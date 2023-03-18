defmodule CanneryWeb.RangeLive.Index do
  @moduledoc """
  Main page for range day mode, where `AmmoGroup`s can be used up.
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup, Ammo, Repo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(search: search) |> display_shot_groups()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil) |> display_shot_groups()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_group,
         %{"id" => id}
       ) do
    socket
    |> assign(
      page_title: gettext("Record Shots"),
      ammo_group: Ammo.get_ammo_group!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit Shot Records"),
      shot_group: ActivityLog.get_shot_group!(id, current_user)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("New Shot Records"),
      shot_group: %ShotGroup{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Shot Records"),
      search: nil,
      shot_group: nil
    )
    |> display_shot_groups()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Shot Records"),
      search: search,
      shot_group: nil
    )
    |> display_shot_groups()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    {:ok, _} =
      ActivityLog.get_shot_group!(id, current_user)
      |> ActivityLog.delete_shot_group(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_groups()}
  end

  def handle_event(
        "toggle_staged",
        %{"ammo_group_id" => ammo_group_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)

    {:ok, _ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    prompt = dgettext("prompts", "Ammo unstaged succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_groups()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.range_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.range_index_path(Endpoint, :search, search_term))}
  end

  @spec display_shot_groups(Socket.t()) :: Socket.t()
  defp display_shot_groups(%{assigns: %{search: search, current_user: current_user}} = socket) do
    shot_groups =
      ActivityLog.list_shot_groups(search, current_user)
      |> Repo.preload(ammo_group: :ammo_type)

    ammo_groups = Ammo.list_staged_ammo_groups(current_user)
    chart_data = shot_groups |> get_chart_data_for_shot_group()

    socket
    |> assign(
      ammo_groups: ammo_groups,
      chart_data: chart_data,
      shot_groups: shot_groups
    )
  end

  @spec get_chart_data_for_shot_group([ShotGroup.t()]) :: [map()]
  defp get_chart_data_for_shot_group(shot_groups) do
    shot_groups
    |> Repo.preload(ammo_group: :ammo_type)
    |> Enum.group_by(fn %{date: date} -> date end, fn %{count: count} -> count end)
    |> Enum.map(fn {date, rounds} ->
      sum = Enum.sum(rounds)

      %{
        date: date,
        count: sum,
        label: gettext("Rounds shot: %{count}", count: sum)
      }
    end)
    |> Enum.sort_by(fn %{date: date} -> date end, Date)
  end
end
