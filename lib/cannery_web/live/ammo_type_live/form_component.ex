defmodule CanneryWeb.AmmoTypeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_component

  alias Cannery.Ammo

  @impl true
  def update(%{ammo_type: ammo_type} = assigns, socket) do
    changeset = Ammo.change_ammo_type(ammo_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"ammo_type" => ammo_type_params}, socket) do
    changeset =
      socket.assigns.ammo_type
      |> Ammo.change_ammo_type(ammo_type_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"ammo_type" => ammo_type_params}, socket) do
    save_ammo_type(socket, socket.assigns.action, ammo_type_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="title text-xl text-primary-500">
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="ammo_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="grid grid-cols-3 justify-center items-center space-y-4"
      >
        <%= label(f, :name, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :name, class: "text-center col-span-2 input input-primary") %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :name) %>
        </div>

        <%= label(f, :desc, class: "mr-4 title text-lg text-primary-500") %>
        <%= textarea(f, :desc,
          class: "text-center col-span-2 input input-primary",
          phx_hook: "MaintainAttrs") %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :desc) %>
        </div>

        <%= label(f, :case_material, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :case_material, class: "text-center col-span-2 input input-primary") %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :case_material) %>
        </div>

        <%= label(f, :bullet_type, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :bullet_type, class: "text-center col-span-2 input input-primary") %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :bullet_type) %>
        </div>

        <%= label(f, :grain, class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :grain,
          step: "any",
          class: "text-center col-span-2 input input-primary",
          min: 0) %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :grain) %>
        </div>

        <%= label(f, :manufacturer, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :manufacturer, class: "text-center col-span-2 input input-primary") %>
        <div class="col-span-3 text-center">
          <%= error_tag(f, :manufacturer) %>
        </div>

        <%= submit("Save",
          phx_disable_with: "Saving...",
          class: "mx-auto col-span-3 btn btn-primary") %>
      </.form>
    </div>
    """
  end

  defp save_ammo_type(socket, :edit, ammo_type_params) do
    case Ammo.update_ammo_type(socket.assigns.ammo_type, ammo_type_params) do
      {:ok, _ammo_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo type updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_ammo_type(socket, :new, ammo_type_params) do
    case Ammo.create_ammo_type(ammo_type_params) do
      {:ok, _ammo_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo type created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
