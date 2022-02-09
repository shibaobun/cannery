defmodule CanneryWeb.TagLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Tags.Tag index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.TagLive.TagCard
  alias Cannery.Tags
  alias Cannery.Tags.Tag

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_tags()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Tag"))
    |> assign(:tag, Tags.get_tag!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Tag"))
    |> assign(:tag, %Tag{bg_color: Tags.random_bg_color(), text_color: "#ffffff"})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Tags"))
    |> assign(:tag, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Tags.get_tag!(id)
    {:ok, _} = Tags.delete_tag(tag)
    socket = socket |> put_flash(:info, dgettext("prompts", "Tag deleted succesfully"))
    {:noreply, socket |> display_tags()}
  end

  defp display_tags(socket) do
    tags = Tags.list_tags(socket.assigns.current_user)
    socket |> assign(tags: tags)
  end
end
