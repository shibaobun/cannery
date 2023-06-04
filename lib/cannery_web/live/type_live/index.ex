defmodule CanneryWeb.TypeLive.Index do
  @moduledoc """
  Liveview for showing a Cannery.Ammo.Type index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.Type}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(class: :all, show_used: false, search: search) |> list_types()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(class: :all, show_used: false, search: nil) |> list_types()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{name: type_name} = type = Ammo.get_type!(id, current_user)

    socket
    |> assign(
      page_title: gettext("Edit %{type_name}", type_name: type_name),
      type: type
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("New Type"),
      type: %{Ammo.get_type!(id, current_user) | id: nil}
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("New Type"),
      type: %Type{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Catalog"),
      search: nil,
      type: nil
    )
    |> list_types()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Catalog"),
      search: search,
      type: nil
    )
    |> list_types()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: name} = Ammo.get_type!(id, current_user) |> Ammo.delete_type!(current_user)
    prompt = dgettext("prompts", "%{name} deleted succesfully", name: name)
    {:noreply, socket |> put_flash(:info, prompt) |> list_types()}
  end

  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> list_types()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/catalog")}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/catalog/search/#{search_term}")}
  end

  def handle_event("change_class", %{"type" => %{"class" => "rifle"}}, socket) do
    {:noreply, socket |> assign(:class, :rifle) |> list_types()}
  end

  def handle_event("change_class", %{"type" => %{"class" => "shotgun"}}, socket) do
    {:noreply, socket |> assign(:class, :shotgun) |> list_types()}
  end

  def handle_event("change_class", %{"type" => %{"class" => "pistol"}}, socket) do
    {:noreply, socket |> assign(:class, :pistol) |> list_types()}
  end

  def handle_event("change_class", %{"type" => %{"class" => _all}}, socket) do
    {:noreply, socket |> assign(:class, :all) |> list_types()}
  end

  defp list_types(
         %{assigns: %{class: class, search: search, current_user: current_user}} = socket
       ) do
    socket
    |> assign(
      types: Ammo.list_types(current_user, class: class, search: search),
      types_count: Ammo.get_types_count!(current_user)
    )
  end
end
