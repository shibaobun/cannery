defmodule CanneryWeb.ErrorJSONTest do
  use CanneryWeb.ConnCase, async: true
  alias CanneryWeb.ErrorJSON

  test "renders 404" do
    assert ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not found"}}
  end

  test "renders 500" do
    assert ErrorJSON.render("500.json", %{}) == %{errors: %{detail: "Internal server error"}}
  end
end
