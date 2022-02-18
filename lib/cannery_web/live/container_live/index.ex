defmodule CanneryWeb.ContainerLive.Index do
  @moduledoc """
  Liveview for showing Cannery.Containers.Container index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.ContainerCard
  alias Cannery.{Containers, Containers.Container}
  alias CanneryWeb.Endpoint
  alias Ecto.Changeset

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_containers()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Container"))
    |> assign(:container, Containers.get_container!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(:page_title, gettext("New Container")) |> assign(:container, %Container{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, gettext("Listing Containers")) |> assign(:container, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    socket =
      socket.assigns.containers
      |> Enum.find(fn %{id: container_id} -> id == container_id end)
      |> case do
        nil ->
          socket |> put_flash(:error, dgettext("errors", "Could not find that container"))

        container ->
          case Containers.delete_container(container, current_user) do
            {:ok, %{name: container_name}} ->
              prompt = dgettext("prompts", "%{name} has been deleted", name: container_name)
              socket |> put_flash(:info, prompt) |> display_containers()

            {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
              ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")

              prompt =
                dgettext(
                  "errors",
                  "Could not delete %{name}: %{error}",
                  name: changeset |> Changeset.get_field(:name, "container"),
                  error: ammo_groups_error
                )

              socket |> put_flash(:error, prompt)

            {:error, changeset} ->
              socket |> put_flash(:error, changeset |> changeset_errors())
          end
      end

    {:noreply, socket}
  end

  defp display_containers(%{assigns: %{current_user: current_user}} = socket) do
    socket |> assign(containers: Containers.list_containers(current_user))
  end
end
