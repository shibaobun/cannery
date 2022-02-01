defmodule CanneryWeb.ContainerLive.Index do
  @moduledoc """
  Liveview for showing Cannery.Containers.Container index
  """

  use CanneryWeb, :live_view

  alias Cannery.Containers
  alias Cannery.Containers.Container

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
    Containers.get_container!(id) |> Containers.delete_container!()
    {:noreply, socket |> display_containers()}
  end

  defp display_containers(%{assigns: %{current_user: current_user}} = socket) do
    containers = Containers.list_containers(current_user)
    socket |> assign(containers: containers)
  end
end
