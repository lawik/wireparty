defmodule WirepartyWeb.PageController do
  use WirepartyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
