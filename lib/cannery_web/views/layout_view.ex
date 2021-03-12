defmodule CanneryWeb.LayoutView do
  use CanneryWeb, :view
  
  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Cannery | #{conn.assigns.title}"
    else
      "Cannery"
    end
  end
end
