defmodule Captablex.Repo.Migrations.ModifyStockClassesForConfiguration do
  use Ecto.Migration

  def change do
    alter table(:stock_classes) do
      remove :class_type
      remove :name
      add :security_type, :string, null: false
      add :series, :string, null: false
    end

    create index(:stock_classes, [:security_type])
    create index(:stock_classes, [:series])
    create unique_index(:stock_classes, [:security_type, :series])
  end
end
