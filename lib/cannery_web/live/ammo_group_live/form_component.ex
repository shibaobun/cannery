defmodule CanneryWeb.AmmoGroupLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Cannery.{Accounts.User, Ammo, Containers, Containers.Container}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:ammo_group => AmmoGroup.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{ammo_group: _ammo_group} = assigns, socket) do
    socket |> assign(assigns) |> update()
  end

  @spec update(Socket.t()) :: {:ok, Socket.t()}
  def update(%{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket) do
    changeset = Ammo.change_ammo_group(ammo_group)
    containers = Containers.list_containers(current_user)
    ammo_types = Ammo.list_ammo_types(current_user)
    {:ok, socket |> assign(changeset: changeset, containers: containers, ammo_types: ammo_types)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"ammo_group" => ammo_group_params},
        %{assigns: %{ammo_group: ammo_group}} = socket
      ) do
    socket = socket |> assign(:changeset, ammo_group |> Ammo.change_ammo_group(ammo_group_params))
    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{"ammo_group" => ammo_group_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_ammo_group(socket, action, ammo_group_params)
  end

  # HTML Helpers
  @spec container_options([Container.t()]) :: [{String.t(), Container.id()}]
  defp container_options(containers) do
    containers |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  @spec ammo_type_options([AmmoType.t()]) :: [{String.t(), AmmoType.id()}]
  defp ammo_type_options(ammo_types) do
    ammo_types |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  # Save Helpers

  defp save_ammo_group(
         %{assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         ammo_group_params
       ) do
    socket =
      case Ammo.update_ammo_group(ammo_group, ammo_group_params, current_user) do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo group updated successfully")
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_ammo_group(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         ammo_group_params
       ) do
    socket =
      case Ammo.create_ammo_group(ammo_group_params, current_user) do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo group created successfully")
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
