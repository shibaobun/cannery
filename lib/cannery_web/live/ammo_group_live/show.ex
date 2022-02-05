defmodule CanneryWeb.AmmoGroupLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_view
  import CanneryWeb.ContainerLive.ContainerCard
  alias Cannery.{Ammo, Repo}

  @impl true
  def mount(_params, session, socket) do
    socket = socket |> assign_defaults(session)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        ammo_group: Ammo.get_ammo_group!(id) |> Repo.preload([:container, :ammo_type])
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    socket.assigns.ammo_group |> Ammo.delete_ammo_group!()
    {:noreply, socket |> push_redirect(to: Routes.ammo_group_index_path(socket, :index))}
  end

  defp page_title(:show), do: "Show Ammo group"
  defp page_title(:edit), do: "Edit Ammo group"
end
