defmodule CanneryWeb.AmmoTypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_view
  import CanneryWeb.AmmoGroupLive.AmmoGroupCard
  alias Cannery.Ammo

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, %{assigns: %{current_user: current_user}} = socket) do
    ammo_type = Ammo.get_ammo_type!(id)
    ammo_groups = ammo_type |> Ammo.list_ammo_groups_for_type(current_user)

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        ammo_type: ammo_type,
        ammo_groups: ammo_groups,
        avg_cost_per_round: ammo_type |> Ammo.get_average_cost_for_ammo_type!()
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
