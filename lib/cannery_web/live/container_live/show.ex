defmodule CanneryWeb.ContainerLive.Show do
  @moduledoc """
  Liveview for showing and editing a Cannery.Containers.Container
  """

  use CanneryWeb, :live_view
  import CanneryWeb.AmmoGroupLive.AmmoGroupCard
  alias Cannery.{Containers, Repo}

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        container: Containers.get_container!(id) |> Repo.preload(:ammo_groups)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    socket =
      socket.assigns.container
      |> Containers.delete_container(socket.assigns.current_user)
      |> case do
        {:ok, container} ->
          socket
          |> put_flash(
            :info,
            dgettext("prompts", "%{name} has been deleted", name: container.name)
          )
          |> push_redirect(to: Routes.container_index_path(socket, :index))

        {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
          ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")

          socket
          |> put_flash(
            :error,
            dgettext("errors", "Could not delete container: %{error}", error: ammo_groups_error)
          )

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  defp page_title(:show), do: gettext("Show Container")
  defp page_title(:edit), do: gettext("Edit Container")
end
