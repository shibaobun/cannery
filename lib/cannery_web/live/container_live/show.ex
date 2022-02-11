defmodule CanneryWeb.ContainerLive.Show do
  @moduledoc """
  Liveview for showing and editing a Cannery.Containers.Container
  """

  use CanneryWeb, :live_view
  import CanneryWeb.AmmoGroupLive.AmmoGroupCard
  alias Cannery.{Containers, Repo}
  alias Ecto.Changeset

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
    socket =
      socket
      |> assign(
        page_title: page_title(live_action),
        container: Containers.get_container!(id, current_user) |> Repo.preload(:ammo_groups)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
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
end
