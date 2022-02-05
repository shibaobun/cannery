defmodule CanneryWeb.AmmoTypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_view
  import CanneryWeb.AmmoGroupLive.AmmoGroupCard
  alias Cannery.{Ammo, Repo}

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        ammo_type: Ammo.get_ammo_type!(id) |> Repo.preload(:ammo_groups)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    socket.assigns.ammo_type |> Ammo.delete_ammo_type!()
    {:noreply, socket |> push_redirect(to: Routes.ammo_type_index_path(socket, :index))}
  end

  defp page_title(:show), do: "Show Ammo type"
  defp page_title(:edit), do: "Edit Ammo type"
end
