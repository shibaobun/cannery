defmodule CanneryWeb.InviteLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Invites.Invite
  """

  use CanneryWeb, :live_component

  alias Cannery.Invites
  alias Ecto.Changeset

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
    changeset = socket.assigns.invite |> Invites.change_invite(invite_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"invite" => invite_params}, socket) do
    save_invite(socket, socket.assigns.action, invite_params)
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
        id="invite-form"
        class="grid grid-cols-3 justify-center items-center space-y-4"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @changeset.action do %>
          <div class="invalid-feedback col-span-3 text-center">
            <%= changeset_errors(@changeset) %>
          </div>
        <% end %>

        <%= label(f, :name, gettext("Name"), class: "title text-lg text-primary-500") %>
        <%= text_input(f, :name, class: "input input-primary col-span-2") %>
        <%= error_tag(f, :name, "col-span-3") %>

        <%= label(f, :uses_left, gettext("Uses left"), class: "title text-lg text-primary-500") %>
        <%= number_input(f, :uses_left, min: 0, class: "input input-primary col-span-2") %>
        <%= error_tag(f, :uses_left, "col-span-3") %>

        <%= submit(dgettext("actions", "Save"),
          class: "mx-auto btn btn-primary col-span-3",
          phx_disable_with: dgettext("prompts", "Saving...")
        ) %>
      </.form>
    </div>
    """
  end

  defp save_invite(socket, :edit, invite_params) do
    case Invites.update_invite(socket.assigns.invite, invite_params) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("prompts", "Invite updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_invite(socket, :new, invite_params) do
    case Invites.create_invite(socket.assigns.current_user, invite_params) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("prompts", "Invite created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
