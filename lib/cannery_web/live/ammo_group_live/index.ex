defmodule CanneryWeb.AmmoGroupLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Ammo.AmmoGroup index
  """

  use CanneryWeb, :live_view

  alias Cannery.Ammo
  alias Cannery.Ammo.AmmoGroup

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> assign(:ammo_groups, list_ammo_groups())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Ammo group")
    |> assign(:ammo_group, Ammo.get_ammo_group!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ammo group")
    |> assign(:ammo_group, %AmmoGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Ammo groups")
    |> assign(:ammo_group, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ammo_group = Ammo.get_ammo_group!(id)
    {:ok, _} = Ammo.delete_ammo_group(ammo_group)

    {:noreply, socket |> assign(:ammo_groups, list_ammo_groups())}
  end

  defp list_ammo_groups do
    Ammo.list_ammo_groups()
  end
end
