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
alias Captablex.Accounts

# Clear existing data
Repo.delete_all(Captablex.Transaction)
Repo.delete_all(Captablex.SecurityIssuance)
Repo.delete_all(Captablex.StockClass)
Repo.delete_all(Captablex.Stakeholder)

# Create stakeholders using the Accounts context
{:ok, jane} =
  Accounts.create_stakeholder(%{
    name: "Jane Doe",
    stakeholder_type: "Individual",
    email: "jane@example.com",
    tax_id: "123-45-6789"
  })

{:ok, john} =
  Accounts.create_stakeholder(%{
    name: "John Smith",
    stakeholder_type: "Individual",
    email: "john@example.com",
    tax_id: "987-65-4321"
  })

{:ok, acme_ventures} =
  Accounts.create_stakeholder(%{
    name: "Acme Ventures",
    stakeholder_type: "Institution",
    email: "invest@acmeventures.com",
    tax_id: "12-3456789"
  })

IO.puts("✅ Seeded stakeholders:")
IO.puts("   - 3 stakeholders (2 founders, 1 investor)")
IO.puts("")
IO.puts("📝 Next steps:")
IO.puts("   1. Run: mix run priv/repo/seeds_config.exs")
IO.puts("   2. Run: mix run priv/repo/seeds_stock_classes.exs")
IO.puts("   3. Use the dashboard to issue securities")
