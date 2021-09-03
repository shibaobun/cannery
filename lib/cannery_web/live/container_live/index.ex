defmodule CanneryWeb.ContainerLive.Index do
  use CanneryWeb, :live_view

  alias Cannery.Containers
  alias Cannery.Containers.Container

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> assign(:containers, list_containers())}
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
    container = Containers.get_container!(id)
    {:ok, _} = Containers.delete_container(container)

    {:noreply, socket |> assign(:containers, list_containers())}
  end

  defp list_containers do
    Containers.list_containers()
  end
end
