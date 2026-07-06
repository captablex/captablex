defmodule Captablex.Settings.ConfigurationOption do
  use Ecto.Schema
  import Ecto.Changeset

  schema "configuration_options" do
    field :option_type, :string
    field :value, :string
    field :display_order, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(configuration_option, attrs) do
    configuration_option
    |> cast(attrs, [:option_type, :value, :display_order])
    |> validate_required([:option_type, :value])
    |> validate_inclusion(:option_type, ["security_type", "stakeholder_type", "series"])
    |> unique_constraint([:option_type, :value])
  end
end
