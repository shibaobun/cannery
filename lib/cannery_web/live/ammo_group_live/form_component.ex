defmodule CanneryWeb.AmmoGroupLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_component

  alias Cannery.{Ammo, Containers}
  alias Cannery.{Ammo.AmmoType, Containers.Container}
  alias Ecto.Changeset

  @impl true
  def update(%{ammo_group: ammo_group} = assigns, socket) do
    socket = socket |> assign(assigns)

    changeset = Ammo.change_ammo_group(ammo_group)
    containers = Containers.list_containers(socket.assigns.current_user)
    ammo_types = Ammo.list_ammo_types()

    {:ok, socket |> assign(changeset: changeset, containers: containers, ammo_types: ammo_types)}
  end

  @impl true
  def handle_event("validate", %{"ammo_group" => ammo_group_params}, socket) do
    ammo_group_params = ammo_group_params |> Map.put("user_id", socket.assigns.current_user.id)

    changeset =
      socket.assigns.ammo_group
      |> Ammo.change_ammo_group(ammo_group_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"ammo_group" => ammo_group_params}, socket) do
    ammo_group_params = ammo_group_params |> Map.put("user_id", socket.assigns.current_user.id)
    save_ammo_group(socket, socket.assigns.action, ammo_group_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-center title text-xl text-primary-500">
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="ammo_group-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="grid grid-cols-3 justify-center items-center space-y-4"
      >
        <%= label(f, :count, class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :count,
          class: "text-center col-span-2 input input-primary",
          min: 1
        ) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :count) %>
        </div>

        <%= label(f, :price_paid, class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :price_paid,
          step: "0.01",
          class: "text-center col-span-2 input input-primary"
        ) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :price_paid) %>
        </div>

        <%= label(f, :notes, class: "mr-4 title text-lg text-primary-500") %>
        <%= textarea(f, :notes,
          class: "text-center col-span-2 input input-primary",
          phx_hook: "MaintainAttrs"
        ) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :notes) %>
        </div>

        <%= label(f, :ammo_type_id, class: "mr-4 title text-lg text-primary-500") %>
        <%= select(f, :ammo_type_id, ammo_type_options(@ammo_types),
          class: "text-center col-span-2 input input-primary"
        ) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :ammo_type_id) %>
        </div>

        <%= label(f, :container, class: "mr-4 title text-lg text-primary-500") %>
        <%= select(f, :container_id, container_options(@containers),
          class: "text-center col-span-2 input input-primary"
        ) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :container_id) %>
        </div>

        <%= submit("Save",
          phx_disable_with: "Saving...",
          class: "mx-auto col-span-3 btn btn-primary"
        ) %>
      </.form>
    </div>
    """
  end

  # HTML Helpers
  @spec container_options([Container.t()]) :: [{String.t(), Container.id()}]
  defp container_options(containers) do
    containers |> Enum.map(fn container -> {container.name, container.id} end)
  end

  @spec ammo_type_options([AmmoType.t()]) :: [{String.t(), AmmoType.id()}]
  defp ammo_type_options(ammo_types) do
    ammo_types |> Enum.map(fn ammo_type -> {ammo_type.name, ammo_type.id} end)
  end

  # Save Helpers

  defp save_ammo_group(socket, :edit, ammo_group_params) do
    socket.assigns.ammo_group
    |> Ammo.update_ammo_group(ammo_group_params)
    |> case do
      {:ok, _ammo_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo group updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_ammo_group(socket, :new, ammo_group_params) do
    case Ammo.create_ammo_group(ammo_group_params) do
      {:ok, _ammo_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo group created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
