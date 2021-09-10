defmodule CanneryWeb.InviteLive.Index do
  use CanneryWeb, :live_view

  alias Cannery.Invites
  alias Cannery.Invites.Invite

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> assign(invites: list_invites())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Invite")
    |> assign(:invite, Invites.get_invite!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Invite")
    |> assign(:invite, %Invite{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Invites")
    |> assign(:invite, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invite = Invites.get_invite!(id)
    {:ok, _} = Invites.delete_invite(invite)

    {:noreply, assign(socket, :invites, list_invites())}
  end

  defp list_invites do
    Invites.list_invites()
  end
end
