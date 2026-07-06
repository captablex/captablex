defmodule Captablex.Settings do
  @moduledoc """
  The Settings context - manages configuration options for dropdowns.
  """

  import Ecto.Query, warn: false
  alias Captablex.Repo
  alias Captablex.Settings.ConfigurationOption

  @doc """
  Returns the list of configuration options for a given type.
  """
  def list_options(option_type) do
    ConfigurationOption
    |> where([o], o.option_type == ^option_type)
    |> order_by([o], o.display_order)
    |> Repo.all()
  end

  @doc """
  Returns all configuration options grouped by type.
  """
  def list_all_options do
    ConfigurationOption
    |> order_by([o], [o.option_type, o.display_order])
    |> Repo.all()
    |> Enum.group_by(& &1.option_type)
  end

  @doc """
  Gets a single configuration option.
  """
  def get_option!(id), do: Repo.get!(ConfigurationOption, id)

  @doc """
  Creates a configuration option.
  """
  def create_option(attrs \\ %{}) do
    %ConfigurationOption{}
    |> ConfigurationOption.changeset(attrs)
    |> Repo.insert()
    |> broadcast_change(:option_created)
  end

  @doc """
  Updates a configuration option.
  """
  def update_option(%ConfigurationOption{} = option, attrs) do
    option
    |> ConfigurationOption.changeset(attrs)
    |> Repo.update()
    |> broadcast_change(:option_updated)
  end

  @doc """
  Deletes a configuration option.
  """
  def delete_option(%ConfigurationOption{} = option) do
    option
    |> Repo.delete()
    |> broadcast_change(:option_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking option changes.
  """
  def change_option(%ConfigurationOption{} = option, attrs \\ %{}) do
    ConfigurationOption.changeset(option, attrs)
  end

  @doc """
  Checks if any configuration options exist (for first-run detection).
  """
  def has_configuration? do
    Repo.exists?(ConfigurationOption)
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
