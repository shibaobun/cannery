defmodule CanneryWeb.AmmoTypeLive.Index do
  @moduledoc """
  Liveview for showing a Cannery.Ammo.AmmoType index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.AmmoType}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(show_used: false, search: search) |> list_ammo_types()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(show_used: false, search: nil) |> list_ammo_types()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{name: ammo_type_name} = ammo_type = Ammo.get_ammo_type!(id, current_user)

    socket
    |> assign(
      page_title: gettext("Edit %{ammo_type_name}", ammo_type_name: ammo_type_name),
      ammo_type: ammo_type
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("New Ammo type"),
      ammo_type: %{Ammo.get_ammo_type!(id, current_user) | id: nil}
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("New Ammo type"),
      ammo_type: %AmmoType{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Catalog"),
      search: nil,
      ammo_type: nil
    )
    |> list_ammo_types()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Catalog"),
      search: search,
      ammo_type: nil
    )
    |> list_ammo_types()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: name} = Ammo.get_ammo_type!(id, current_user) |> Ammo.delete_ammo_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: name)

    {:noreply, socket |> put_flash(:info, prompt) |> list_ammo_types()}
  end

  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> list_ammo_types()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.ammo_type_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply,
     socket |> push_patch(to: Routes.ammo_type_index_path(Endpoint, :search, search_term))}
  end

  defp list_ammo_types(%{assigns: %{search: search, current_user: current_user}} = socket) do
    socket |> assign(ammo_types: Ammo.list_ammo_types(search, current_user))
  end
end
