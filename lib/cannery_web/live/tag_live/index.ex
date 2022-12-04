defmodule CanneryWeb.TagLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Tags.Tag index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.TagCard
  alias Cannery.{Tags, Tags.Tag}
  alias CanneryWeb.{Endpoint, ViewHelpers}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(:search, search) |> display_tags()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:search, nil) |> display_tags()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit Tag"),
      tag: Tags.get_tag!(id, current_user)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("New Tag"),
      tag: %Tag{bg_color: ViewHelpers.random_color(), text_color: "#ffffff"}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Tags"),
      search: nil,
      tag: nil
    )
    |> display_tags()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Tags"),
      search: search,
      tag: nil
    )
    |> display_tags()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: tag_name} = Tags.get_tag!(id, current_user) |> Tags.delete_tag!(current_user)
    prompt = dgettext("prompts", "%{name} deleted succesfully", name: tag_name)
    {:noreply, socket |> put_flash(:info, prompt) |> display_tags()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.tag_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.tag_index_path(Endpoint, :search, search_term))}
  end

  defp display_tags(%{assigns: %{search: search, current_user: current_user}} = socket) do
    socket |> assign(tags: Tags.list_tags(search, current_user))
  end
end
