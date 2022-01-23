defmodule CanneryWeb.InviteLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Invites.Invite index
  """

  use CanneryWeb, :live_view

  alias Cannery.Invites
  alias Cannery.Invites.Invite

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_invites()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Invite", invite: Invites.get_invite!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(page_title: "New Invite", invite: %Invite{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: "Listing Invites", invite: nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invite = Invites.get_invite!(id)
    {:ok, _} = Invites.delete_invite(invite)
    {:noreply, socket |> display_invites()}
  end

  def handle_event("set_unlimited", %{"id" => id}, socket) do
    id |> Invites.get_invite!() |> Invites.update_invite(%{"uses_left" => nil})
    {:noreply, socket |> display_invites()}
  end

  def handle_event("enable", %{"id" => id}, socket) do
    attrs = %{"uses_left" => nil, "disabled_at" => nil}
    id |> Invites.get_invite!() |> Invites.update_invite(attrs)
    {:noreply, socket |> display_invites()}
  end

  def handle_event("disable", %{"id" => id}, socket) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    attrs = %{"uses_left" => 0, "disabled_at" => now}
    id |> Invites.get_invite!() |> Invites.update_invite(attrs)
    {:noreply, socket |> display_invites()}
  end

  # redisplays invites to socket
  defp display_invites(socket) do
    invites = Invites.list_invites()
    socket |> assign(:invites, invites)
  end
end
