defmodule CanneryWeb.LayoutView do
  use CanneryWeb, :view
  alias Cannery.{Accounts}
  
  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Cannery | #{conn.assigns.title}"
    else
      "Cannery"
    end
  end
end
