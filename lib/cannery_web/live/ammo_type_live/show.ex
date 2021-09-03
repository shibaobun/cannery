defmodule CanneryWeb.AmmoTypeLive.Show do
  use CanneryWeb, :live_view

  alias Cannery.Ammo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ammo_type, Ammo.get_ammo_type!(id))}
  end

  defp page_title(:show), do: "Show Ammo type"
  defp page_title(:edit), do: "Edit Ammo type"
end
