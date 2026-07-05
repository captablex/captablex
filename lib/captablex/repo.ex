defmodule Captablex.Repo do
  use Ecto.Repo,
    otp_app: :captablex,
    adapter: Ecto.Adapters.Postgres

  @doc """
  A small callback to handle dynamic repos in tests
  """
  def init(_type, config), do: {:ok, config}
end
