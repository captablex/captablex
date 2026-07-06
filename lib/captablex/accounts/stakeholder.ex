defmodule Captablex.Accounts.Stakeholder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stakeholders" do
    field :name, :string
    field :stakeholder_type, :string
    field :email, :string
    field :tax_id, :string

    timestamps()
  end

  @doc false
  def changeset(stakeholder, attrs) do
    stakeholder
    |> cast(attrs, [:name, :stakeholder_type, :email, :tax_id])
    |> validate_required([:name, :stakeholder_type])
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
  end
end
