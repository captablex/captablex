defmodule Captablex.Repo.Migrations.CreateConfigurationOptions do
  use Ecto.Migration

  def change do
    create table(:configuration_options) do
      add :option_type, :string, null: false
      add :value, :string, null: false
      add :display_order, :integer, default: 0

      timestamps()
    end

    create index(:configuration_options, [:option_type])
    create unique_index(:configuration_options, [:option_type, :value])
  end
end
