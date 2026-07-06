defmodule Captablex.CapTable.StockClass do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_classes" do
    field :security_type, :string
    field :series, :string
    field :shares_authorized, :integer
    field :par_value, :decimal
    field :price_per_share, :decimal

    timestamps()
  end

  @doc false
  def changeset(stock_class, attrs) do
    stock_class
    |> cast(attrs, [:security_type, :series, :shares_authorized, :par_value, :price_per_share])
    |> validate_required([:security_type, :series, :shares_authorized])
    |> validate_number(:shares_authorized, greater_than: 0)
    |> validate_number(:par_value, greater_than_or_equal_to: 0)
    |> validate_number(:price_per_share, greater_than_or_equal_to: 0)
    |> unique_constraint([:security_type, :series])
  end

  @doc """
  Returns the display name for a stock class.
  Format: "Security Type - Series"
  """
  def display_name(%__MODULE__{security_type: security_type, series: series}) do
    "#{stock_class.security_type} - #{stock_class.series}"
  end
end
