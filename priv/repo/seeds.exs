# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Captablex.Repo.insert!(%Captablex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Captablex.Repo

# Clear existing data
Repo.delete_all(Captablex.Transaction)
Repo.delete_all(Captablex.SecurityIssuance)
Repo.delete_all(Captablex.StockClass)
Repo.delete_all(Captablex.Stakeholder)

# Create stakeholders
{:ok, jane} =
  Captablex.create_stakeholder(%{
    name: "Jane Doe",
    stakeholder_type: "individual",
    email: "jane@example.com",
    tax_id: "123-45-6789"
  })

{:ok, john} =
  Captablex.create_stakeholder(%{
    name: "John Smith",
    stakeholder_type: "individual",
    email: "john@example.com",
    tax_id: "987-65-4321"
  })

{:ok, acme_ventures} =
  Captablex.create_stakeholder(%{
    name: "Acme Ventures",
    stakeholder_type: "institution",
    email: "invest@acmeventures.com",
    tax_id: "12-3456789"
  })

# Create stock classes
{:ok, common} =
  Captablex.create_stock_class(%{
    class_type: "common",
    name: "Common Stock",
    shares_authorized: 10_000_000,
    par_value: Decimal.new("0.0001"),
    price_per_share: Decimal.new("0.01")
  })

{:ok, preferred_a} =
  Captablex.create_stock_class(%{
    class_type: "preferred",
    name: "Series A Preferred Stock",
    shares_authorized: 2_000_000,
    par_value: Decimal.new("0.0001"),
    price_per_share: Decimal.new("2.50")
  })

# Issue securities
{:ok, jane_security} =
  Captablex.issue_security(%{
    stakeholder_id: jane.id,
    stock_class_id: common.id,
    shares: 4_000_000,
    issue_date: ~D[2024-01-15],
    certificate_id: "CS-001"
  })

{:ok, john_security} =
  Captablex.issue_security(%{
    stakeholder_id: john.id,
    stock_class_id: common.id,
    shares: 2_500_000,
    issue_date: ~D[2024-01-15],
    certificate_id: "CS-002"
  })

{:ok, acme_security} =
  Captablex.issue_security(%{
    stakeholder_id: acme_ventures.id,
    stock_class_id: preferred_a.id,
    shares: 1_000_000,
    issue_date: ~D[2024-03-01],
    certificate_id: "PS-A-001"
  })

# Create transactions
Captablex.create_transaction(%{
  transaction_type: "issuance",
  transaction_date: ~D[2024-01-15],
  quantity: 4_000_000,
  price_per_share: Decimal.new("0.01"),
  stakeholder_id: jane.id,
  security_id: jane_security.id
})

Captablex.create_transaction(%{
  transaction_type: "issuance",
  transaction_date: ~D[2024-01-15],
  quantity: 2_500_000,
  price_per_share: Decimal.new("0.01"),
  stakeholder_id: john.id,
  security_id: john_security.id
})

Captablex.create_transaction(%{
  transaction_type: "issuance",
  transaction_date: ~D[2024-03-01],
  quantity: 1_000_000,
  price_per_share: Decimal.new("2.50"),
  stakeholder_id: acme_ventures.id,
  security_id: acme_security.id
})

IO.puts("✅ Seeded cap table with sample data:")
IO.puts("   - 3 stakeholders (2 founders, 1 investor)")
IO.puts("   - 2 stock classes (Common, Series A Preferred)")
IO.puts("   - 3 security issuances (7.5M shares total)")
IO.puts("   - 3 transactions")
