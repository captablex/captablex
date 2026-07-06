defmodule Captablex.CapTable.StockClass do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_classes" do
    field :security_type, :string
    field :series, :string
    field :shares_authorized, :integer
    field :par_value, :decimal
    field :price_per_share, :decimal
    field :liquidation_preference_multiple, :decimal
    field :participation_type, :string
    field :seniority_rank, :integer

    timestamps()
  end

  @doc false
  def changeset(stock_class, attrs) do
    stock_class
    |> cast(attrs, [
      :security_type,
      :series,
      :shares_authorized,
      :par_value,
      :price_per_share,
      :liquidation_preference_multiple,
      :participation_type,
      :seniority_rank
    ])
    |> validate_required([:security_type, :series, :shares_authorized])
    |> validate_number(:shares_authorized, greater_than: 0)
    |> validate_number(:liquidation_preference_multiple, greater_than_or_equal_to: 0)
    |> validate_number(:seniority_rank, greater_than_or_equal_to: 0)
    |> validate_inclusion(:participation_type, ["participating", "non-participating"])
    |> unique_constraint([:security_type, :series])
  end

  @doc """
  Returns a display name for the stock class in the format:
  "Security Type - Series"

  ## Examples

      iex> display_name(%StockClass{security_type: "Common Stock", series: "Seed"})
      "Common Stock - Seed"
  """
  def display_name(stock_class) do
    "#{stock_class.security_type} - #{stock_class.series}"
  end
end
