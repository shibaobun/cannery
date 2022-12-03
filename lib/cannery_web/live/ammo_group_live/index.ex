defmodule CanneryWeb.AmmoGroupLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Ammo.AmmoGroup index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.AmmoGroup, Containers}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(show_used: false, search: search) |> display_ammo_groups()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(show_used: false, search: nil) |> display_ammo_groups()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_ammo_groups()}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_group,
         %{"id" => id}
       ) do
    socket
    |> assign(
      page_title: gettext("Record shots"),
      ammo_group: Ammo.get_ammo_group!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :move, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Move ammo"),
      ammo_group: Ammo.get_ammo_group!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit ammo"),
      ammo_group: Ammo.get_ammo_group!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    socket
    |> assign(
      page_title: dgettext("actions", "Add Ammo"),
      ammo_group: %{Ammo.get_ammo_group!(id, current_user) | id: nil}
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: dgettext("actions", "Add Ammo"),
      ammo_group: %AmmoGroup{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Ammo"),
      search: nil,
      ammo_group: nil
    )
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Ammo"),
      search: search,
      ammo_group: nil
    )
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    Ammo.get_ammo_group!(id, current_user) |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo deleted succesfully")

    {:noreply, socket |> put_flash(:info, prompt) |> display_ammo_groups()}
  end

  @impl true
  def handle_event(
        "toggle_staged",
        %{"ammo_group_id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    ammo_group = Ammo.get_ammo_group!(id, current_user)

    {:ok, _ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> display_ammo_groups()}
  end

  @impl true
  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> display_ammo_groups()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.ammo_group_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    socket =
      socket |> push_patch(to: Routes.ammo_group_index_path(Endpoint, :search, search_term))

    {:noreply, socket}
  end

  defp display_ammo_groups(
         %{assigns: %{search: search, current_user: current_user, show_used: show_used}} = socket
       ) do
    ammo_groups = Ammo.list_ammo_groups(search, show_used, current_user)
    ammo_types_count = Ammo.get_ammo_types_count!(current_user)
    containers_count = Containers.get_containers_count!(current_user)

    socket
    |> assign(
      ammo_groups: ammo_groups,
      ammo_types_count: ammo_types_count,
      containers_count: containers_count
    )
  end
end
