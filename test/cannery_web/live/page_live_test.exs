defmodule CanneryWeb.HomeLiveTest do
  use CanneryWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to Cannery"
    assert render(page_live) =~ "Welcome to Cannery"
  end
end
