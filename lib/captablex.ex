defmodule Captablex do
  @moduledoc """
  Captablex keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Captablex.Repo

  defmodule Stakeholder do
    use Ecto.Schema
    import Ecto.Changeset

    schema "stakeholders" do
      field :name, :string
      field :stakeholder_type, :string
      field :email, :string
      field :tax_id, :string

      has_many :securities, Captablex.SecurityIssuance
      has_many :transactions, Captablex.Transaction

      timestamps()
    end

    def changeset(stakeholder, attrs) do
      stakeholder
      |> cast(attrs, [:name, :stakeholder_type, :email, :tax_id])
      |> validate_required([:name, :stakeholder_type])
      |> validate_inclusion(:stakeholder_type, ["individual", "institution"])
    end
  end

  defmodule StockClass do
    use Ecto.Schema
    import Ecto.Changeset

    schema "stock_classes" do
      field :security_type, :string
      field :series, :string
      field :shares_authorized, :integer
      field :par_value, :decimal
      field :price_per_share, :decimal

      has_many :securities, Captablex.SecurityIssuance

      timestamps()

      def display_name(stock_class) do
        "#{stock_class.security_type} - #{stock_class.series}"
      end
    end

    def changeset(stock_class, attrs) do
      stock_class
      |> cast(attrs, [:class_type, :name, :shares_authorized, :par_value, :price_per_share])
      |> validate_required([:class_type, :name, :shares_authorized])
      |> validate_inclusion(:class_type, ["common", "preferred"])
      |> validate_number(:shares_authorized, greater_than: 0)
    end
  end

  defmodule SecurityIssuance do
    use Ecto.Schema
    import Ecto.Changeset

    schema "securities" do
      field :shares, :integer
      field :issue_date, :date
      field :certificate_id, :string

      belongs_to :stakeholder, Captablex.Stakeholder
      belongs_to :stock_class, Captablex.StockClass

      timestamps()
    end

    def changeset(security, attrs) do
      security
      |> cast(attrs, [:shares, :issue_date, :certificate_id, :stakeholder_id, :stock_class_id])
      |> validate_required([:shares, :issue_date, :stakeholder_id, :stock_class_id])
      |> validate_number(:shares, greater_than: 0)
      |> foreign_key_constraint(:stakeholder_id)
      |> foreign_key_constraint(:stock_class_id)
    end
  end

  defmodule Transaction do
    use Ecto.Schema
    import Ecto.Changeset

    schema "transactions" do
      field :transaction_type, :string
      field :transaction_date, :date
      field :quantity, :integer
      field :price_per_share, :decimal

      belongs_to :stakeholder, Captablex.Stakeholder
      belongs_to :security, Captablex.SecurityIssuance

      timestamps()
    end

    def changeset(transaction, attrs) do
      transaction
      |> cast(attrs, [
        :transaction_type,
        :transaction_date,
        :quantity,
        :price_per_share,
        :stakeholder_id,
        :security_id
      ])
      |> validate_required([:transaction_type, :transaction_date, :quantity, :stakeholder_id])
      |> validate_inclusion(:transaction_type, [
        "issuance",
        "transfer",
        "cancellation",
        "exercise"
      ])
    end
  end

  # Stakeholder functions
  def list_stakeholders do
    Repo.all(Stakeholder)
  end

  def get_stakeholder!(id), do: Repo.get!(Stakeholder, id)

  def create_stakeholder(attrs \\ %{}) do
    %Stakeholder{}
    |> Stakeholder.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, stakeholder} ->
        Phoenix.PubSub.broadcast(
          Captablex.PubSub,
          "captablex:updates",
          {:stakeholder_created, stakeholder}
        )

        {:ok, stakeholder}

      error ->
        error
    end
  end

  # Stock Class functions
  def list_stock_classes do
    Repo.all(StockClass)
  end

  def get_stock_class!(id), do: Repo.get!(StockClass, id)

  def create_stock_class(attrs \\ %{}) do
    %StockClass{}
    |> StockClass.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, stock_class} ->
        Phoenix.PubSub.broadcast(
          Captablex.PubSub,
          "captablex:updates",
          {:stock_class_created, stock_class}
        )

        {:ok, stock_class}

      error ->
        error
    end
  end

  # Security Issuance functions
  def list_securities do
    Repo.all(SecurityIssuance)
    |> Repo.preload([:stakeholder, :stock_class])
  end

  def get_security!(id) do
    Repo.get!(SecurityIssuance, id)
    |> Repo.preload([:stakeholder, :stock_class])
  end

  def issue_security(attrs \\ %{}) do
    %SecurityIssuance{}
    |> SecurityIssuance.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, security} ->
        security = Repo.preload(security, [:stakeholder, :stock_class])

        # Create a transaction record for the issuance
        {:ok, _transaction} =
          create_transaction(%{
            stakeholder_id: security.stakeholder_id,
            security_id: security.id,
            transaction_type: "issuance",
            transaction_date: security.issue_date,
            quantity: security.shares,
            price_per_share: Map.get(attrs, "price_per_share") || Map.get(attrs, :price_per_share)
          })

        Phoenix.PubSub.broadcast(
          Captablex.PubSub,
          "captablex:updates",
          {:security_issued, security}
        )

        {:ok, security}

      error ->
        error
    end
  end

  # Transaction functions
  def list_transactions do
    from(t in Transaction,
      order_by: [desc: t.transaction_date],
      preload: [:stakeholder, :security]
    )
    |> Repo.all()
  end

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, transaction} ->
        transaction = Repo.preload(transaction, [:stakeholder, :security])

        Phoenix.PubSub.broadcast(
          Captablex.PubSub,
          "captablex:updates",
          {:transaction_created, transaction}
        )

        {:ok, transaction}

      error ->
        error
    end
  end

  # Ownership calculation
  def calculate_ownership_breakdown do
    securities = list_securities()
    total_shares = Enum.reduce(securities, 0, fn sec, acc -> acc + sec.shares end)

    securities
    |> Enum.group_by(& &1.stakeholder_id)
    |> Enum.map(fn {stakeholder_id, secs} ->
      shares = Enum.reduce(secs, 0, fn sec, acc -> acc + sec.shares end)

      percentage =
        if total_shares > 0, do: (shares / total_shares * 100) |> Float.round(2), else: 0.0

      stakeholder = Enum.at(secs, 0).stakeholder

      {stakeholder_id,
       %{
         stakeholder: stakeholder,
         shares: shares,
         percentage: percentage
       }}
    end)
    |> Map.new()
  end

  def get_total_shares_outstanding do
    from(s in SecurityIssuance, select: sum(s.shares))
    |> Repo.one()
    |> Kernel.||(0)
  end

  def get_total_shares_authorized do
    from(sc in StockClass, select: sum(sc.shares_authorized))
    |> Repo.one()
    |> Kernel.||(0)
  end
end
