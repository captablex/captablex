# Script for populating stock classes from configuration options
# Run with: mix run priv/repo/seeds_stock_classes.exs

import Ecto.Query
alias Captablex.Repo
alias Captablex.CapTable
alias Captablex.CapTable.StockClass

# Only seed if no stock classes exist
if Repo.aggregate(StockClass, :count) == 0 do
  IO.puts("Seeding stock classes...")

  # Create Common Stock classes for different series
  {:ok, _} =
    CapTable.create_stock_class(%{
      security_type: "Common Stock",
      series: "Seed",
      shares_authorized: 10_000_000,
      par_value: Decimal.new("0.0001"),
      price_per_share: Decimal.new("0.50")
    })

  {:ok, _} =
    CapTable.create_stock_class(%{
      security_type: "Common Stock",
      series: "Series A",
      shares_authorized: 15_000_000,
      par_value: Decimal.new("0.0001"),
      price_per_share: Decimal.new("1.00")
    })

  # Create Preferred Stock classes
  {:ok, _} =
    CapTable.create_stock_class(%{
      security_type: "Preferred Stock",
      series: "Series A",
      shares_authorized: 5_000_000,
      par_value: Decimal.new("0.0001"),
      price_per_share: Decimal.new("2.00")
    })

  {:ok, _} =
    CapTable.create_stock_class(%{
      security_type: "Preferred Stock",
      series: "Series B",
      shares_authorized: 3_000_000,
      par_value: Decimal.new("0.0001"),
      price_per_share: Decimal.new("5.00")
    })

  IO.puts("✓ Stock classes seeded successfully!")
else
  IO.puts("Stock classes already exist, skipping seed.")
end
