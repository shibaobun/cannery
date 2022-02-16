defmodule CanneryWeb.InviteLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Invites.Invite index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.{InviteCard, UserCard}
  alias Cannery.{Accounts, Invites, Invites.Invite}
  alias CanneryWeb.{Endpoint, HomeLive}
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, session, socket) do
    %{assigns: %{current_user: current_user}} = socket = socket |> assign_defaults(session)

    socket =
      if current_user |> Map.get(:role) == :admin do
        socket |> display_invites()
      else
        prompt = dgettext("errors", "You are not authorized to view this page")
        return_to = Routes.live_path(Endpoint, HomeLive)
        socket |> put_flash(:error, prompt) |> push_redirect(to: return_to)
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, socket |> apply_action(live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: gettext("Edit Invite"), invite: Invites.get_invite!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(page_title: gettext("New Invite"), invite: %Invite{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(page_title: gettext("Listing Invites"), invite: nil)
  end

  @impl true
  def handle_event(
        "delete_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    %{name: invite_name} =
      id |> Invites.get_invite!(current_user) |> Invites.delete_invite!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: invite_name)
    {:noreply, socket |> put_flash(:info, prompt) |> display_invites()}
  end

  def handle_event(
        "set_unlimited",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{"uses_left" => nil}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} updated succesfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  def handle_event(
        "enable_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{"uses_left" => nil, "disabled_at" => nil}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} enabled succesfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  def handle_event(
        "disable_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{"uses_left" => 0, "disabled_at" => now}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} disabled succesfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("copy_to_clipboard", _, socket) do
    prompt = dgettext("prompts", "Copied to clipboard")
    {:noreply, socket |> put_flash(:info, prompt)}
  end

  @impl true
  def handle_event(
        "delete_user",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    %{email: user_email} = Accounts.get_user!(id) |> Accounts.delete_user!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: user_email)

    {:noreply, socket |> put_flash(:info, prompt) |> display_invites()}
  end

  defp display_invites(%{assigns: %{current_user: current_user}} = socket) do
    invites = Invites.list_invites(current_user) |> Enum.sort_by(fn %{name: name} -> name end)
    all_users = Accounts.list_all_users_by_role(current_user)

    admins =
      all_users
      |> Map.get(:admin, [])
      |> Enum.reject(fn %{id: user_id} -> user_id == current_user.id end)
      |> Enum.sort_by(fn %{email: email} -> email end)

    users = all_users |> Map.get(:user, []) |> Enum.sort_by(fn %{email: email} -> email end)
    socket |> assign(invites: invites, admins: admins, users: users)
  end
end
