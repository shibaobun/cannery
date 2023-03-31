defmodule CanneryWeb.RangeLive.Index do
  @moduledoc """
  Main page for range day mode, where `Pack`s can be used up.
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, ActivityLog.ShotRecord, Ammo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(class: :all, search: search) |> display_shot_records()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(class: :all, search: nil) |> display_shot_records()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_record,
         %{"id" => id}
       ) do
    socket
    |> assign(
      page_title: gettext("Record Shots"),
      pack: Ammo.get_pack!(id, current_user)
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      page_title: gettext("Edit Shot Record"),
      shot_record: ActivityLog.get_shot_record!(id, current_user)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      page_title: gettext("New Shot Records"),
      shot_record: %ShotRecord{}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Shot Records"),
      search: nil,
      shot_record: nil
    )
    |> display_shot_records()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Shot Records"),
      search: search,
      shot_record: nil
    )
    |> display_shot_records()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    {:ok, _} =
      ActivityLog.get_shot_record!(id, current_user)
      |> ActivityLog.delete_shot_record(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_records()}
  end

  def handle_event(
        "toggle_staged",
        %{"pack_id" => pack_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    pack = Ammo.get_pack!(pack_id, current_user)

    {:ok, _pack} = pack |> Ammo.update_pack(%{"staged" => !pack.staged}, current_user)

    prompt = dgettext("prompts", "Ammo unstaged succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_records()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.range_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.range_index_path(Endpoint, :search, search_term))}
  end

  def handle_event("change_class", %{"type" => %{"class" => "rifle"}}, socket) do
    {:noreply, socket |> assign(:class, :rifle) |> display_shot_records()}
  end

  def handle_event("change_class", %{"type" => %{"class" => "shotgun"}}, socket) do
    {:noreply, socket |> assign(:class, :shotgun) |> display_shot_records()}
  end

  def handle_event("change_class", %{"type" => %{"class" => "pistol"}}, socket) do
    {:noreply, socket |> assign(:class, :pistol) |> display_shot_records()}
  end

  def handle_event("change_class", %{"type" => %{"class" => _all}}, socket) do
    {:noreply, socket |> assign(:class, :all) |> display_shot_records()}
  end

  @spec display_shot_records(Socket.t()) :: Socket.t()
  defp display_shot_records(
         %{assigns: %{class: class, search: search, current_user: current_user}} = socket
       ) do
    shot_records = ActivityLog.list_shot_records(search, class, current_user)
    packs = Ammo.list_staged_packs(current_user)
    chart_data = shot_records |> get_chart_data_for_shot_record()
    original_counts = packs |> Ammo.get_original_counts(current_user)
    cprs = packs |> Ammo.get_cprs(current_user)
    last_used_dates = packs |> ActivityLog.get_last_used_dates(current_user)
    shot_record_count = ActivityLog.get_shot_record_count!(current_user)

    socket
    |> assign(
      packs: packs,
      original_counts: original_counts,
      cprs: cprs,
      last_used_dates: last_used_dates,
      chart_data: chart_data,
      shot_records: shot_records,
      shot_record_count: shot_record_count
    )
  end

  @spec get_chart_data_for_shot_record([ShotRecord.t()]) :: [map()]
  defp get_chart_data_for_shot_record(shot_records) do
    shot_records
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
