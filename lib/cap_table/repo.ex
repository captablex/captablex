defmodule CapTable.Repo do
  use Ecto.Repo,
    otp_app: :cap_table,
    adapter: Ecto.Adapters.SQLite3
end
