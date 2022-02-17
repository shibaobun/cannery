defmodule CanneryWeb.HomeLiveTest do
  @moduledoc """
  Tests the home page
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext

  @moduletag :home_live_test

  test "disconnected and connected render", %{conn: conn} do
    {:ok, home_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ gettext("Welcome to %{name}", name: "Cannery")
    assert render(home_live) =~ gettext("Welcome to %{name}", name: "Cannery")
  end
end
