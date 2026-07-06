defmodule Captablex.Repo.Migrations.AddLiquidationPreferencesToStockClasses do
  use Ecto.Migration

  def change do
    alter table(:stock_classes) do
      add :liquidation_preference_multiple, :decimal, precision: 10, scale: 2, default: 1.0
      add :participation_type, :string, default: "non-participating"
      add :seniority_rank, :integer, default: 0
    end

    create index(:stock_classes, [:seniority_rank])
  end
end
