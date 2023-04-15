defmodule CanneryWeb.HomeLive do
  @moduledoc """
  Liveview for the home page
  """

  use CanneryWeb, :live_view
  alias Cannery.Accounts

  @version Mix.Project.config()[:version]

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_users_by_role(:admin)
    {:ok, socket |> assign(page_title: gettext("Home"), admins: admins, version: @version)}
  end
end
