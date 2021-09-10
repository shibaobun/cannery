defmodule CanneryWeb.InviteLive.Show do
  use CanneryWeb, :live_view

  alias Cannery.Invites

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:invite, Invites.get_invite!(id))}
  end

  defp page_title(:show), do: "Show Invite"
  defp page_title(:edit), do: "Edit Invite"
end
