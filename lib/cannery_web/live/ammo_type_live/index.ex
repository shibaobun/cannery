defmodule CanneryWeb.AmmoTypeLive.Index do
  @moduledoc """
  Liveview for showing a Cannery.Ammo.AmmoType index
  """

  use CanneryWeb, :live_view

  alias Cannery.Ammo
  alias Cannery.Ammo.AmmoType

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> assign(:ammo_types, list_ammo_types())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Ammo type")
    |> assign(:ammo_type, Ammo.get_ammo_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ammo type")
    |> assign(:ammo_type, %AmmoType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Ammo types")
    |> assign(:ammo_type, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ammo_type = Ammo.get_ammo_type!(id)
    {:ok, _} = Ammo.delete_ammo_type(ammo_type)

    {:noreply, socket |> assign(:ammo_types, list_ammo_types())}
  end

  defp list_ammo_types do
    Ammo.list_ammo_types()
  end
end
