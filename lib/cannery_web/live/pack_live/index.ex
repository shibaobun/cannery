defmodule CanneryWeb.PackLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Ammo.Pack index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.Pack, Containers}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    socket =
      socket
      |> assign(class: :all, show_used: false, search: search)
      |> display_packs()

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(class: :all, show_used: false, search: nil) |> display_packs()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_packs()}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_record,
         %{"id" => id}
       ) do
    socket
    |> assign(
      page_title: gettext("Record shots"),
      pack: Ammo.get_pack!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :move, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Move ammo"),
      pack: Ammo.get_pack!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit ammo"),
      pack: Ammo.get_pack!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    socket
    |> assign(
      page_title: dgettext("actions", "Add Ammo"),
      pack: %{Ammo.get_pack!(id, current_user) | id: nil}
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: dgettext("actions", "Add Ammo"),
      pack: %Pack{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Ammo"),
      search: nil,
      pack: nil
    )
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Ammo"),
      search: search,
      pack: nil
    )
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    Ammo.get_pack!(id, current_user) |> Ammo.delete_pack!(current_user)

    prompt = dgettext("prompts", "Ammo deleted succesfully")

    {:noreply, socket |> put_flash(:info, prompt) |> display_packs()}
  end

  def handle_event(
        "toggle_staged",
        %{"pack_id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    pack = Ammo.get_pack!(id, current_user)

    {:ok, _pack} = pack |> Ammo.update_pack(%{"staged" => !pack.staged}, current_user)

    {:noreply, socket |> display_packs()}
  end

  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> display_packs()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.pack_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    socket = socket |> push_patch(to: Routes.pack_index_path(Endpoint, :search, search_term))

    {:noreply, socket}
  end

  def handle_event("change_class", %{"ammo_type" => %{"class" => "rifle"}}, socket) do
    {:noreply, socket |> assign(:class, :rifle) |> display_packs()}
  end

  def handle_event("change_class", %{"ammo_type" => %{"class" => "shotgun"}}, socket) do
    {:noreply, socket |> assign(:class, :shotgun) |> display_packs()}
  end

  def handle_event("change_class", %{"ammo_type" => %{"class" => "pistol"}}, socket) do
    {:noreply, socket |> assign(:class, :pistol) |> display_packs()}
  end

  def handle_event("change_class", %{"ammo_type" => %{"class" => _all}}, socket) do
    {:noreply, socket |> assign(:class, :all) |> display_packs()}
  end

  defp display_packs(
         %{
           assigns: %{
             class: class,
             search: search,
             current_user: current_user,
             show_used: show_used
           }
         } = socket
       ) do
    # get total number of packs to determine whether to display onboarding
    # prompts
    packs_count = Ammo.get_packs_count!(current_user, true)
    packs = Ammo.list_packs(search, class, current_user, show_used)
    ammo_types_count = Ammo.get_ammo_types_count!(current_user)
    containers_count = Containers.get_containers_count!(current_user)

    socket
    |> assign(
      packs: packs,
      ammo_types_count: ammo_types_count,
      containers_count: containers_count,
      packs_count: packs_count
    )
  end
end
