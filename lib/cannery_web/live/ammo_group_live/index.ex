defmodule CanneryWeb.AmmoGroupLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Ammo.AmmoGroup index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.AmmoGroup, Repo}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_ammo_groups()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :move, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Move Ammo group"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Ammo group"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("actions", "Add Ammo"))
    |> assign(:ammo_group, %AmmoGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, gettext("Ammo groups")) |> assign(:ammo_group, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    Ammo.get_ammo_group!(id, current_user) |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo group deleted succesfully")

    {:noreply, socket |> put_flash(:info, prompt) |> display_ammo_groups()}
  end

  @impl true
  def handle_event(
        "toggle_staged",
        %{"ammo_group_id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    ammo_group = Ammo.get_ammo_group!(id, current_user)

    {:ok, _ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> display_ammo_groups()}
  end

  defp display_ammo_groups(%{assigns: %{current_user: current_user}} = socket) do
    ammo_groups = Ammo.list_ammo_groups(current_user) |> Repo.preload([:ammo_type, :container])
    socket |> assign(:ammo_groups, ammo_groups)
  end
end
