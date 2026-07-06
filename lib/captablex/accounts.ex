defmodule Captablex.Accounts do
  @moduledoc """
  The Accounts context - manages stakeholders.
  """

  import Ecto.Query, warn: false
  alias Captablex.Repo
  alias Captablex.Accounts.Stakeholder

  @doc """
  Returns the list of stakeholders.
  """
  def list_stakeholders do
    Repo.all(Stakeholder)
  end

  @doc """
  Gets a single stakeholder.
  """
  def get_stakeholder!(id), do: Repo.get!(Stakeholder, id)

  @doc """
  Creates a stakeholder.
  """
  def create_stakeholder(attrs \\ %{}) do
    %Stakeholder{}
    |> Stakeholder.changeset(attrs)
    |> Repo.insert()
    |> broadcast_change(:stakeholder_created)
  end

  @doc """
  Updates a stakeholder.
  """
  def update_stakeholder(%Stakeholder{} = stakeholder, attrs) do
    stakeholder
    |> Stakeholder.changeset(attrs)
    |> Repo.update()
    |> broadcast_change(:stakeholder_updated)
  end

  @doc """
  Deletes a stakeholder.
  """
  def delete_stakeholder(%Stakeholder{} = stakeholder) do
    stakeholder
    |> Repo.delete()
    |> broadcast_change(:stakeholder_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stakeholder changes.
  """
  def change_stakeholder(%Stakeholder{} = stakeholder, attrs \\ %{}) do
    Stakeholder.changeset(stakeholder, attrs)
  end

  defp broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(
      Captablex.PubSub,
      "captablex:updates",
      {event, result}
    )

    {:ok, result}
  end

  defp broadcast_change({:error, _} = error, _event), do: error
end
