defmodule CanneryWeb.TagLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Tags.Tag index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.TagCard
  alias Cannery.{Tags, Tags.Tag}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket |> display_tags()}

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_tags}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Tag"))
    |> assign(:tag, Tags.get_tag!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Tag"))
    |> assign(:tag, %Tag{bg_color: Tags.random_bg_color(), text_color: "#ffffff"})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, gettext("Tags")) |> assign(:tag, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: tag_name} = Tags.get_tag!(id, current_user) |> Tags.delete_tag!(current_user)
    prompt = dgettext("prompts", "%{name} deleted succesfully", name: tag_name)
    {:noreply, socket |> put_flash(:info, prompt) |> display_tags()}
  end

  defp display_tags(%{assigns: %{current_user: current_user}} = socket) do
    socket |> assign(tags: Tags.list_tags(current_user))
  end
end
