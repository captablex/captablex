defmodule CapTableWeb.PageController do
  use CapTableWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
