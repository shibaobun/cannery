defmodule CanneryWeb.ContainerLive.Show do
  @moduledoc """
  Liveview for showing and editing a Cannery.Containers.Container
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.{AmmoGroupCard, TagCard}
  alias Cannery.{Containers, Repo, Tags}
  alias CanneryWeb.Endpoint
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _,
        %{assigns: %{current_user: current_user, live_action: live_action}} = socket
      ) do
    {:noreply,
     socket |> assign(page_title: page_title(live_action)) |> render_container(id, current_user)}
  end

  @impl true
  def handle_event(
        "delete_tag",
        %{"tag-id" => tag_id},
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      case Tags.get_tag(tag_id, current_user) do
        {:ok, tag} ->
          _count = Containers.remove_tag!(container, tag, current_user)

          prompt =
            dgettext("prompts", "%{tag_name} has been removed from %{container_name}",
              tag_name: tag.name,
              container_name: container.name
            )

          socket |> put_flash(:info, prompt) |> render_container(container.id, current_user)

        {:error, error_string} ->
          socket |> put_flash(:error, error_string)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete_container",
        _,
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      Containers.delete_container(container, current_user)
      |> case do
        {:ok, %{name: container_name}} ->
          prompt = dgettext("prompts", "%{name} has been deleted", name: container_name)

          socket
          |> put_flash(:info, prompt)
          |> push_redirect(to: Routes.container_index_path(socket, :index))

        {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
          ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")

          prompt =
            dgettext("errors", "Could not delete %{name}: %{error}",
              name: changeset |> Changeset.get_field(:name, "container"),
              error: ammo_groups_error
            )

          socket |> put_flash(:error, prompt)

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  defp page_title(:show), do: gettext("Show Container")
  defp page_title(:edit), do: gettext("Edit Container")
  defp page_title(:add_tag), do: gettext("Add Tag to Container")

  @spec render_container(Socket.t(), Container.id(), User.t()) :: Socket.t()
  defp render_container(socket, id, current_user) do
    container =
      Containers.get_container!(id, current_user)
      |> Repo.preload([:ammo_groups, :tags], force: true)

    socket |> assign(container: container)
  end
end
