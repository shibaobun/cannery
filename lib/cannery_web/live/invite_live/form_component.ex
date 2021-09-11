defmodule CanneryWeb.InviteLive.FormComponent do
  use CanneryWeb, :live_component

  alias Cannery.Invites

  @impl true
  def update(%{invite: invite} = assigns, socket) do
    changeset = Invites.change_invite(invite)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"invite" => invite_params}, socket) do
    changeset =
      socket.assigns.invite
      |> Invites.change_invite(invite_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"invite" => invite_params}, socket) do
    save_invite(socket, socket.assigns.action, invite_params)
  end

  defp save_invite(socket, :edit, invite_params) do
    case Invites.update_invite(socket.assigns.invite, invite_params) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invite updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
      end
  end

  defp save_invite(socket, :new, invite_params) do
    case Invites.create_invite(socket.assigns.current_user, invite_params) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invite created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
