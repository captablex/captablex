defmodule Captablex.CapTable do
  @moduledoc """
  The CapTable context - manages stock classes.
  """

  import Ecto.Query, warn: false
  alias Captablex.Repo
  alias Captablex.CapTable.StockClass

  @doc """
  Returns the list of stock classes.
  """
  def list_stock_classes do
    StockClass
    |> order_by([s], [s.security_type, s.series])
    |> Repo.all()
  end

  @doc """
  Gets a single stock class.
  """
  def get_stock_class!(id), do: Repo.get!(StockClass, id)

  @doc """
  Creates a stock class.
  """
  def create_stock_class(attrs \\ %{}) do
    %StockClass{}
    |> StockClass.changeset(attrs)
    |> Repo.insert()
    |> broadcast_change(:stock_class_created)
  end

  @doc """
  Updates a stock class.
  """
  def update_stock_class(%StockClass{} = stock_class, attrs) do
    stock_class
    |> StockClass.changeset(attrs)
    |> Repo.update()
    |> broadcast_change(:stock_class_updated)
  end

  @doc """
  Deletes a stock class.
  """
  def delete_stock_class(%StockClass{} = stock_class) do
    stock_class
    |> Repo.delete()
    |> broadcast_change(:stock_class_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stock class changes.
  """
  def change_stock_class(%StockClass{} = stock_class, attrs \\ %{}) do
    StockClass.changeset(stock_class, attrs)
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
