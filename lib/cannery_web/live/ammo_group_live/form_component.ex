defmodule CanneryWeb.AmmoGroupLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.{Ammo, Accounts.User, Containers, Containers.Container}
  alias Cannery.Ammo.{AmmoType, AmmoGroup}
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
        <%= if @changeset.action do %>
          <div class="invalid-feedback col-span-3 text-center">
            <%= changeset_errors(@changeset) %>
          </div>
        <% end %>

        <%= label(f, :ammo_type_id, gettext("Ammo type"), class: "mr-4 title text-lg text-primary-500") %>
        <%= select(f, :ammo_type_id, ammo_type_options(@ammo_types),
          class: "text-center col-span-2 input input-primary"
        ) %>
        <%= error_tag(f, :ammo_type_id, "col-span-3 text-center") %>

        <%= label(f, :count, gettext("Count"), class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :count,
          class: "text-center col-span-2 input input-primary",
          min: 1
        ) %>
        <%= error_tag(f, :count, "col-span-3 text-center") %>

        <%= label(f, :price_paid, gettext("Price paid"), class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :price_paid,
          step: "0.01",
          class: "text-center col-span-2 input input-primary"
        ) %>
        <%= error_tag(f, :price_paid, "col-span-3 text-center") %>

        <%= label(f, :notes, gettext("Notes"), class: "mr-4 title text-lg text-primary-500") %>
        <%= textarea(f, :notes,
          class: "text-center col-span-2 input input-primary",
          phx_hook: "MaintainAttrs"
        ) %>
        <%= error_tag(f, :notes, "col-span-3 text-center") %>

        <%= label(f, :container, gettext("Container"), class: "mr-4 title text-lg text-primary-500") %>
        <%= select(f, :container_id, container_options(@containers),
          class: "text-center col-span-2 input input-primary"
        ) %>
        <%= error_tag(f, :container_id, "col-span-3 text-center") %>

        <%= submit(dgettext("actions", "Save"),
          phx_disable_with: dgettext("prompts", "Saving..."),
          class: "mx-auto col-span-3 btn btn-primary"
        ) %>
      </.form>
    </div>
    """
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
