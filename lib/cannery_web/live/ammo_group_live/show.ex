defmodule CanneryWeb.AmmoGroupLive.Show do
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
     |> assign(:ammo_group, Ammo.get_ammo_group!(id))}
  end

  defp page_title(:show), do: "Show Ammo group"
  defp page_title(:edit), do: "Edit Ammo group"
end
