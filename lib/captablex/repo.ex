defmodule Captablex.Repo do
  use Ecto.Repo,
    otp_app: :captablex,
    adapter: Ecto.Adapters.SQLite3
end
