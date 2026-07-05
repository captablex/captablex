defmodule CapTable.Repo.Migrations.CreateOcfTables do
  use Ecto.Migration

  def change do
    create table(:stakeholders) do
      add :name, :string, null: false
      add :stakeholder_type, :string, null: false
      add :email, :string
      add :tax_id, :string

      timestamps()
    end

    create index(:stakeholders, [:stakeholder_type])

    create table(:stock_classes) do
      add :class_type, :string, null: false
      add :name, :string, null: false
      add :shares_authorized, :integer, null: false
      add :par_value, :decimal, precision: 10, scale: 4
      add :price_per_share, :decimal, precision: 10, scale: 4

      timestamps()
    end

    create index(:stock_classes, [:class_type])

    create table(:securities) do
      add :shares, :integer, null: false
      add :issue_date, :date, null: false
      add :certificate_id, :string
      add :stakeholder_id, references(:stakeholders, on_delete: :restrict), null: false
      add :stock_class_id, references(:stock_classes, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:securities, [:stakeholder_id])
    create index(:securities, [:stock_class_id])
    create index(:securities, [:issue_date])

    create table(:transactions) do
      add :transaction_type, :string, null: false
      add :transaction_date, :date, null: false
      add :quantity, :integer, null: false
      add :price_per_share, :decimal, precision: 10, scale: 4
      add :stakeholder_id, references(:stakeholders, on_delete: :restrict), null: false
      add :security_id, references(:securities, on_delete: :restrict)

      timestamps()
    end

    create index(:transactions, [:stakeholder_id])
    create index(:transactions, [:security_id])
    create index(:transactions, [:transaction_type])
    create index(:transactions, [:transaction_date])
  end
end
