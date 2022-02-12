defmodule CanneryWeb.LayoutView do
  use CanneryWeb, :view
  alias Cannery.Accounts
  alias CanneryWeb.{Endpoint, HomeLive}

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Cannery | #{conn.assigns.title}"
    else
      "Cannery"
    end
  end
end
