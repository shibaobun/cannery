defmodule CanneryWeb.RangeLive.Index do
  @moduledoc """
  Main page for range day mode, where `AmmoGroup`s can be used up.
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.AmmoGroupCard
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup, Ammo, Repo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket |> display_shot_groups()}

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
    |> assign(:page_title, gettext("Record Shots"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Shot Records"))
    |> assign(:shot_group, ActivityLog.get_shot_group!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Shot Records"))
    |> assign(:shot_group, %ShotGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Shot Records"))
    |> assign(:shot_group, nil)
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

  @spec display_shot_groups(Socket.t()) :: Socket.t()
  defp display_shot_groups(%{assigns: %{current_user: current_user}} = socket) do
    shot_groups =
      ActivityLog.list_shot_groups(current_user) |> Repo.preload(ammo_group: :ammo_type)

    ammo_groups = Ammo.list_staged_ammo_groups(current_user)

    columns = [
      %{label: gettext("Ammo"), key: :name},
      %{label: gettext("Rounds shot"), key: :count},
      %{label: gettext("Notes"), key: :notes},
      %{label: gettext("Date"), key: :date},
      %{label: nil, key: :actions, sortable: false}
    ]

    rows =
      shot_groups
      |> Enum.map(fn shot_group -> shot_group |> get_row_data_for_shot_group(columns) end)

    chart_data =
      shot_groups
      |> Enum.map(fn shot_group ->
        shot_group
        |> get_chart_data_for_shot_group([:name, :count, :notes, :date])
      end)
      |> Enum.sort_by(fn %{date: date} -> date end, Date)

    socket
    |> assign(
      ammo_groups: ammo_groups,
      columns: columns,
      rows: rows,
      chart_data: chart_data,
      shot_groups: shot_groups
    )
  end

  @spec get_chart_data_for_shot_group(ShotGroup.t(), keys :: [atom()]) :: map()
  defp get_chart_data_for_shot_group(shot_group, keys) do
    shot_group = shot_group |> Repo.preload(ammo_group: :ammo_type)

    labels =
      if shot_group.notes do
        [gettext("Notes: %{notes}", notes: shot_group.notes)]
      else
        []
      end

    labels = [
      gettext(
        "Name: %{name}",
        name: shot_group.ammo_group.ammo_type.name
      ),
      gettext(
        "Rounds shot: %{count}",
        count: shot_group.count
      )
      | labels
    ]

    keys
    |> Map.new(fn key ->
      value =
        case key do
          :name -> shot_group.ammo_group.ammo_type.name
          key -> shot_group |> Map.get(key)
        end

      {key, value}
    end)
    |> Map.put(:labels, labels)
  end

  @spec get_row_data_for_shot_group(ShotGroup.t(), [map()]) :: map()
  defp get_row_data_for_shot_group(%{date: date} = shot_group, columns) do
    shot_group = shot_group |> Repo.preload(ammo_group: :ammo_type)
    assigns = %{shot_group: shot_group}

    columns
    |> Map.new(fn %{key: key} ->
      value =
        case key do
          :name ->
            {shot_group.ammo_group.ammo_type.name,
             ~H"""
             <.link
               navigate={Routes.ammo_group_show_path(Endpoint, :show, @shot_group.ammo_group)}
               class="link"
             >
               <%= @shot_group.ammo_group.ammo_type.name %>
             </.link>
             """}

          :date ->
            date |> display_date()

          :actions ->
            ~H"""
            <div class="px-4 py-2 space-x-4 flex justify-center items-center">
              <.link
                patch={Routes.range_index_path(Endpoint, :edit, @shot_group)}
                class="text-primary-600 link"
                data-qa={"edit-#{@shot_group.id}"}
              >
                <i class="fa-fw fa-lg fas fa-edit"></i>
              </.link>

              <.link
                href="#"
                class="text-primary-600 link"
                phx-click="delete"
                phx-value-id={@shot_group.id}
                data-confirm={dgettext("prompts", "Are you sure you want to delete this shot record?")}
                data-qa={"delete-#{@shot_group.id}"}
              >
                <i class="fa-fw fa-lg fas fa-trash"></i>
              </.link>
            </div>
            """

          key ->
            shot_group |> Map.get(key)
        end

      {key, value}
    end)
  end
end
