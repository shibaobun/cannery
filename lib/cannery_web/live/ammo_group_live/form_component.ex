defmodule CanneryWeb.AmmoGroupLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_component

  alias Cannery.Ammo

  @impl true
  def update(%{ammo_group: ammo_group} = assigns, socket) do
    changeset = Ammo.change_ammo_group(ammo_group)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"ammo_group" => ammo_group_params}, socket) do
    changeset =
      socket.assigns.ammo_group
      |> Ammo.change_ammo_group(ammo_group_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"ammo_group" => ammo_group_params}, socket) do
    save_ammo_group(socket, socket.assigns.action, ammo_group_params)
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
        id="ammo_group-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save">

        <%= label f, :count, class: "title text-lg text-primary-500" %>
        <%= number_input f, :count %>
        <%= error_tag f, :count %>

        <%= label f, :price_paid, class: "title text-lg text-primary-500" %>
        <%= number_input f, :price_paid, step: "any" %>
        <%= error_tag f, :price_paid %>

        <%= label f, :notes, class: "title text-lg text-primary-500" %>
        <%= textarea f, :notes, class: "input" %>
        <%= error_tag f, :notes %>

        <%= submit "Save", phx_disable_with: "Saving..." %>
      </.form>
    </div>
    """
  end

  defp save_ammo_group(socket, :edit, ammo_group_params) do
    case Ammo.update_ammo_group(socket.assigns.ammo_group, ammo_group_params) do
      {:ok, _ammo_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo group updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
