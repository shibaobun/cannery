defmodule CanneryWeb.AmmoTypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_view

  alias Cannery.Ammo

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ammo_type, Ammo.get_ammo_type!(id))}
  end

  @impl true
  def handle_event("delete", _, socket) do
    socket.assigns.ammo_type |> Ammo.delete_ammo_type!()
    {:noreply, socket |> push_redirect(to: Routes.ammo_type_index_path(socket, :index))}
  end

  defp page_title(:show), do: "Show Ammo type"
  defp page_title(:edit), do: "Edit Ammo type"
end
