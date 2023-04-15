defmodule CanneryWeb.HomeControllerTest do
  @moduledoc """
  Tests the home page
  """

  use CanneryWeb.ConnCase

  @moduletag :home_controller_test

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to Cannery"
  end
end
