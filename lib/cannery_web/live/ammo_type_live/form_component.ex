defmodule CanneryWeb.AmmoTypeLive.FormComponent do
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
      <h2>
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="ammo_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save">

        <%= label f, :name, class: "title text-lg text-primary-500" %>
        <%= text_input f, :name, class: "input input-primary" %>
        <%= error_tag f, :name %>

        <%= label f, :desc, class: "title text-lg text-primary-500" %>
        <%= text_input f, :desc, class: "input input-primary" %>
        <%= error_tag f, :desc %>

        <%= label f, :case_material, class: "title text-lg text-primary-500" %>
        <%= text_input f, :case_material, class: "input input-primary" %>
        <%= error_tag f, :case_material %>

        <%= label f, :bullet_type, class: "title text-lg text-primary-500" %>
        <%= text_input f, :bullet_type, class: "input input-primary" %>
        <%= error_tag f, :bullet_type %>

        <%= label f, :weight, class: "title text-lg text-primary-500" %>
        <%= number_input f, :weight, step: "any" %>
        <%= error_tag f, :weight %>

        <%= label f, :manufacturer, class: "title text-lg text-primary-500" %>
        <%= text_input f, :manufacturer, class: "input input-primary" %>
        <%= error_tag f, :manufacturer %>

        <%= submit "Save", phx_disable_with: "Saving..." %>
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
