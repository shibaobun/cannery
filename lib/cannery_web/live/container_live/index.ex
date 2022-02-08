defmodule CanneryWeb.ContainerLive.Index do
  @moduledoc """
  Liveview for showing Cannery.Containers.Container index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.ContainerLive.ContainerCard
  alias Cannery.{Containers, Containers.Container}

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_containers()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Container")
    |> assign(:container, Containers.get_container!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Container")
    |> assign(:container, %Container{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Containers")
    |> assign(:container, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    socket =
      socket.assigns.containers
      |> Enum.find(fn %{id: container_id} -> id == container_id end)
      |> case do
        nil ->
          socket |> put_flash(:error, "Could not find that container")

        container ->
          container
          |> Containers.delete_container()
          |> case do
            {:ok, container} ->
              socket
              |> put_flash(:info, "#{container.name} has been deleted")
              |> display_containers()

            {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
              ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")
              socket |> put_flash(:error, "Could not delete container: #{ammo_groups_error}")

            {:error, changeset} ->
              socket |> put_flash(:error, changeset |> changeset_errors())
          end
      end

    {:noreply, socket}
  end

  defp display_containers(%{assigns: %{current_user: current_user}} = socket) do
    containers = Containers.list_containers(current_user)
    socket |> assign(containers: containers)
  end
end
