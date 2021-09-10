defmodule CanneryWeb.HomeController do
  use CanneryWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
