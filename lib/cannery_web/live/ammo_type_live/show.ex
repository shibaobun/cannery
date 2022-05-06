defmodule CanneryWeb.AmmoTypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.AmmoGroupCard
  alias Cannery.Ammo
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"id" => id}, _params, %{assigns: %{current_user: current_user}} = socket) do
    ammo_type = Ammo.get_ammo_type!(id, current_user)

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        ammo_type: ammo_type,
        ammo_groups: ammo_type |> Ammo.list_ammo_groups_for_type(current_user),
        avg_cost_per_round: ammo_type |> Ammo.get_average_cost_for_ammo_type!(current_user)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{ammo_type: ammo_type, current_user: current_user}} = socket
      ) do
    %{name: ammo_type_name} = ammo_type |> Ammo.delete_ammo_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: ammo_type_name)
    redirect_to = Routes.ammo_type_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_redirect(to: redirect_to)}
  end

  defp page_title(:show), do: gettext("Show Ammo type")
  defp page_title(:edit), do: gettext("Edit Ammo type")
end
