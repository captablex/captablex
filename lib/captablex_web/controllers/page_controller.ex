defmodule CaptablexWeb.PageController do
  use CaptablexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
