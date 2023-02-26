defmodule CanneryWeb.HomeController do
  @moduledoc """
  Controller for home page
  """

  use CanneryWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
