defmodule CanneryWeb.ErrorHTMLTest do
  use CanneryWeb.ConnCase, async: true
  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template
  alias CanneryWeb.ErrorHTML

  test "renders 404.html" do
    assert render_to_string(ErrorHTML, "404", "html", []) =~ "Not found"
  end

  test "renders 500.html" do
    assert render_to_string(ErrorHTML, "500", "html", []) =~ "Internal server error"
  end
end
