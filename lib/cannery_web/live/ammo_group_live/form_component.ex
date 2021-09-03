defmodule CanneryWeb.AmmoGroupLive.FormComponent do
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
