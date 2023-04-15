defmodule CanneryWeb.HomeLiveTest do
  @moduledoc """
  Tests the home page
  """

  use CanneryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @moduletag :home_live_test

  test "disconnected and connected render", %{conn: conn} do
    {:ok, home_live, disconnected_html} = live(conn, ~p"/")
    assert disconnected_html =~ "Welcome to Cannery"
    assert render(home_live) =~ "Welcome to Cannery"
  end

  test "displays version number", %{conn: conn} do
    {:ok, home_live, disconnected_html} = live(conn, ~p"/")
    assert disconnected_html =~ Mix.Project.config()[:version]
    assert render(home_live) =~ Mix.Project.config()[:version]
  end
end
