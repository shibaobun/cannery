defmodule CanneryWeb.ErrorViewTest do
  @moduledoc """
  Tests the error view
  """

  use CanneryWeb.ConnCase, async: true
  import CanneryWeb.Gettext
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  @moduletag :error_view_test

  test "renders 404.html" do
    assert render_to_string(CanneryWeb.ErrorView, "404.html", []) =~
             dgettext("errors", "Not found")
  end

  test "renders 500.html" do
    assert render_to_string(CanneryWeb.ErrorView, "500.html", []) =~
             dgettext("errors", "Internal Server Error")
  end
end
