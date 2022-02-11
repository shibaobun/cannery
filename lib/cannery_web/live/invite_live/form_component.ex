defmodule CanneryWeb.InviteLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Invites.Invite
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Invites, Invites.Invite}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:invite => Invite.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{invite: invite} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:changeset, Invites.change_invite(invite))}
  end

  @impl true
  def handle_event(
        "validate",
        %{"invite" => invite_params},
        %{assigns: %{invite: invite}} = socket
      ) do
    {:noreply, socket |> assign(:changeset, invite |> Invites.change_invite(invite_params))}
  end

  def handle_event("save", %{"invite" => invite_params}, %{assigns: %{action: action}} = socket) do
    save_invite(socket, action, invite_params)
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

  defp save_invite(
         %{assigns: %{current_user: current_user, invite: invite, return_to: return_to}} = socket,
         :edit,
         invite_params
       ) do
    socket =
      case invite |> Invites.update_invite(invite_params, current_user) do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_invite(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         invite_params
       ) do
    socket =
      case current_user |> Invites.create_invite(invite_params) do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
