defmodule CanneryWeb.AmmoTypeLive.Index do
  @moduledoc """
  Liveview for showing a Cannery.Ammo.AmmoType index
  """

  use CanneryWeb, :live_view

  alias Cannery.{Ammo, Ammo.AmmoType}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> list_ammo_types()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Ammo type"))
    |> assign(:ammo_type, Ammo.get_ammo_type!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Ammo type"))
    |> assign(:ammo_type, %AmmoType{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, gettext("Listing Ammo types")) |> assign(:ammo_type, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: name} = Ammo.get_ammo_type!(id, current_user) |> Ammo.delete_ammo_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: name)

    {:noreply, socket |> put_flash(:info, prompt) |> list_ammo_types()}
  end

  defp list_ammo_types(%{assigns: %{current_user: current_user}} = socket) do
    socket |> assign(:ammo_types, Ammo.list_ammo_types(current_user))
  end
end
