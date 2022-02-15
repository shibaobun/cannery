defmodule CanneryWeb.Components.MoveAmmoGroupComponent do
  @moduledoc """
  Livecomponent that can move an ammo group to another container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoGroup, Containers}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{
            required(:current_user) => User.t(),
            required(:ammo_group) => AmmoGroup.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{ammo_group: %{container_id: container_id} = ammo_group, current_user: current_user} =
          assigns,
        socket
      ) do
    changeset = Ammo.change_ammo_group(ammo_group)

    containers =
      Containers.list_containers(current_user)
      |> Enum.reject(fn %{id: id} -> id == container_id end)

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset, containers: containers)}
  end

  @impl true
  def handle_event(
        "move",
        %{"container_id" => container_id},
        %{assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}} =
          socket
      ) do
    %{name: container_name} = Containers.get_container!(container_id, current_user)

    socket =
      ammo_group
      |> Ammo.update_ammo_group(%{"container_id" => container_id}, current_user)
      |> case do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo moved to %{name} successfully", name: container_name)

          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
