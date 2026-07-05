defmodule CapTable do
  @moduledoc """
  CapTable keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defmodule Stakeholder do
    use Ecto.Schema
    import Ecto.Changeset

    schema "stakeholders" do
      field :name, :string
      field :stakeholder_type, :string
      field :email, :string
      field :tax_id, :string

      has_many :securities, CapTable.SecurityIssuance
      has_many :transactions, CapTable.Transaction

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
      field :class_type, :string
      field :name, :string
      field :shares_authorized, :integer
      field :par_value, :decimal
      field :price_per_share, :decimal

      has_many :securities, CapTable.SecurityIssuance

      timestamps()
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

      belongs_to :stakeholder, CapTable.Stakeholder
      belongs_to :stock_class, CapTable.StockClass

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

      belongs_to :stakeholder, CapTable.Stakeholder
      belongs_to :security, CapTable.SecurityIssuance

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
end
