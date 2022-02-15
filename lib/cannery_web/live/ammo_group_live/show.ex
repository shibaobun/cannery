defmodule CanneryWeb.AmmoGroupLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.ContainerCard
  alias Cannery.{Ammo, Repo}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session)}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    socket |> assign(page_title: page_title(live_action)) |> apply_action(live_action, params)
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_group,
         %{"id" => id}
       ) do
    socket
    |> assign(:page_title, gettext("Add Shot group"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(
         %{assigns: %{live_action: live_action, current_user: current_user}} = socket,
         action,
         %{"id" => id}
       )
       when action == :edit or action == :show do
    ammo_group = Ammo.get_ammo_group!(id, current_user) |> Repo.preload([:container, :ammo_type])
    {:noreply, socket |> assign(page_title: page_title(live_action), ammo_group: ammo_group)}
  end

  @impl true
  def handle_event(
        "delete",
        _,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    ammo_group |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo group deleted succesfully")
    redirect_to = Routes.ammo_group_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_redirect(to: redirect_to)}
  end

  @impl true
  def handle_event(
        "toggle_staged",
        _,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    {:ok, ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> assign(ammo_group: ammo_group)}
  end

  defp page_title(:show), do: gettext("Show Ammo group")
  defp page_title(:edit), do: gettext("Edit Ammo group")
end
