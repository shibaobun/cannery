defmodule CanneryWeb.ContainerLive.EditTagsComponent do
  @moduledoc """
  Livecomponent that can add or remove a tag to a Container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Containers, Containers.Container, Repo, Tags, Tags.Tag}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:container => Container.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{container: container, current_user: current_user} = assigns, socket) do
    tags = Tags.list_tags(current_user)
    container = container |> Repo.preload(:tags)
    {:ok, socket |> assign(assigns) |> assign(tags: tags, container: container)}
  end

  @impl true
  def handle_event(
        "save",
        %{"tag" => %{"tag_id" => tag_id}},
        %{assigns: %{tags: tags, container: container, current_user: current_user}} = socket
      ) do
    socket =
      case tags |> Enum.find(fn %{id: id} -> tag_id == id end) do
        nil ->
          prompt = dgettext("errors", "Tag could not be added")
          socket |> put_flash(:error, prompt)

        %{name: tag_name} = tag ->
          _container_tag = Containers.add_tag!(container, tag, current_user)
          container = container |> Repo.preload(:tags, force: true)
          prompt = dgettext("prompts", "%{name} added successfully", name: tag_name)
          socket |> put_flash(:info, prompt) |> assign(container: container)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        %{"tag-id" => tag_id},
        %{assigns: %{tags: tags, container: container, current_user: current_user}} = socket
      ) do
    socket =
      case tags |> Enum.find(fn %{id: id} -> tag_id == id end) do
        nil ->
          prompt = dgettext("errors", "Tag could not be removed")
          socket |> put_flash(:error, prompt)

        %{name: tag_name} = tag ->
          _container_tag = Containers.remove_tag!(container, tag, current_user)
          container = container |> Repo.preload(:tags, force: true)
          prompt = dgettext("prompts", "%{name} removed successfully", name: tag_name)
          socket |> put_flash(:info, prompt) |> assign(container: container)
      end

    {:noreply, socket}
  end

  @spec tag_options([Tag.t()], Container.t()) :: [{String.t(), Tag.id()}]
  defp tag_options(tags, %Container{tags: container_tags}) do
    container_tags_map = container_tags |> Enum.map(fn %{id: id} -> id end) |> MapSet.new()

    tags
    |> Enum.reject(fn %{id: id} -> container_tags_map |> MapSet.member?(id) end)
    |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end
end
