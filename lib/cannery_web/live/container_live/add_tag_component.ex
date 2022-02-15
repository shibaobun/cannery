defmodule CanneryWeb.ContainerLive.AddTagComponent do
  @moduledoc """
  Livecomponent that can add a tag to a Container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Containers, Containers.Container, Tags, Tags.Tag}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:container => Container.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{container: _container, current_user: current_user} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:tags, Tags.list_tags(current_user))}
  end

  @impl true
  def handle_event(
        "save",
        %{"tag" => %{"tag_id" => tag_id}},
        %{
          assigns: %{
            tags: tags,
            container: container,
            current_user: current_user,
            return_to: return_to
          }
        } = socket
      ) do
    socket =
      case tags |> Enum.find(fn %{id: id} -> tag_id == id end) do
        nil ->
          prompt = dgettext("errors", "Tag could not be added")
          socket |> put_flash(:error, prompt)

        %{name: tag_name} = tag ->
          _container_tag = Containers.add_tag!(container, tag, current_user)
          prompt = dgettext("prompts", "%{name} added successfully", name: tag_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)
      end

    {:noreply, socket}
  end

  @spec tag_options([Tag.t()]) :: [{String.t(), Tag.id()}]
  defp tag_options(tags) do
    tags |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end
end
