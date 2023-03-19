defmodule CanneryWeb.AmmoGroupLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup}
  alias Cannery.{Ammo, Ammo.AmmoGroup}
  alias Cannery.Containers
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(
        %{"id" => id, "shot_group_id" => shot_group_id},
        _url,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    shot_group = ActivityLog.get_shot_group!(shot_group_id, current_user)

    socket =
      socket
      |> assign(page_title: page_title(live_action), shot_group: shot_group)
      |> display_ammo_group(id)

    {:noreply, socket}
  end

  def handle_params(%{"id" => id}, _url, %{assigns: %{live_action: live_action}} = socket) do
    socket =
      socket
      |> assign(page_title: page_title(live_action))
      |> display_ammo_group(id)

    {:noreply, socket}
  end

  defp page_title(:add_shot_group), do: gettext("Record Shots")
  defp page_title(:edit_shot_group), do: gettext("Edit Shot Records")
  defp page_title(:move), do: gettext("Move Ammo")
  defp page_title(:show), do: gettext("Show Ammo")
  defp page_title(:edit), do: gettext("Edit Ammo")

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    ammo_group |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo deleted succesfully")
    redirect_to = Routes.ammo_group_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_navigate(to: redirect_to)}
  end

  def handle_event(
        "toggle_staged",
        _params,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    {:ok, ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> display_ammo_group(ammo_group)}
  end

  def handle_event(
        "delete_shot_group",
        %{"id" => id},
        %{assigns: %{ammo_group: %{id: ammo_group_id}, current_user: current_user}} = socket
      ) do
    {:ok, _} =
      ActivityLog.get_shot_group!(id, current_user)
      |> ActivityLog.delete_shot_group(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_ammo_group(ammo_group_id)}
  end

  @spec display_ammo_group(Socket.t(), AmmoGroup.t() | AmmoGroup.id()) :: Socket.t()
  defp display_ammo_group(
         %{assigns: %{current_user: current_user}} = socket,
         %AmmoGroup{container_id: container_id} = ammo_group
       ) do
    columns = [
      %{label: gettext("Rounds shot"), key: :count},
      %{label: gettext("Notes"), key: :notes},
      %{label: gettext("Date"), key: :date, type: Date},
      %{label: nil, key: :actions, sortable: false}
    ]

    shot_groups = ActivityLog.list_shot_groups_for_ammo_group(ammo_group, current_user)

    rows =
      shot_groups
      |> Enum.map(fn shot_group ->
        ammo_group |> get_table_row_for_shot_group(shot_group, columns)
      end)

    socket
    |> assign(
      ammo_group: ammo_group,
      original_count: Ammo.get_original_count(ammo_group, current_user),
      percentage_remaining: Ammo.get_percentage_remaining(ammo_group, current_user),
      container: container_id && Containers.get_container!(container_id, current_user),
      shot_groups: shot_groups,
      columns: columns,
      rows: rows
    )
  end

  defp display_ammo_group(%{assigns: %{current_user: current_user}} = socket, id),
    do: display_ammo_group(socket, Ammo.get_ammo_group!(id, current_user))

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)

  @spec get_table_row_for_shot_group(AmmoGroup.t(), ShotGroup.t(), [map()]) :: map()
  defp get_table_row_for_shot_group(ammo_group, %{id: id, date: date} = shot_group, columns) do
    assigns = %{ammo_group: ammo_group, shot_group: shot_group}

    columns
    |> Map.new(fn %{key: key} ->
      value =
        case key do
          :date ->
            assigns = %{id: id, date: date}

            {date,
             ~H"""
             <.date id={"#{@id}-date"} date={@date} />
             """}

          :actions ->
            ~H"""
            <div class="px-4 py-2 space-x-4 flex justify-center items-center">
              <.link
                patch={Routes.ammo_group_show_path(Endpoint, :edit_shot_group, @ammo_group, @shot_group)}
                class="text-primary-600 link"
                aria-label={
                  dgettext("actions", "Edit shot group of %{shot_group_count} shots",
                    shot_group_count: @shot_group.count
                  )
                }
              >
                <i class="fa-fw fa-lg fas fa-edit"></i>
              </.link>

              <.link
                href="#"
                class="text-primary-600 link"
                phx-click="delete_shot_group"
                phx-value-id={@shot_group.id}
                data-confirm={dgettext("prompts", "Are you sure you want to delete this shot record?")}
                aria-label={
                  dgettext("actions", "Delete shot record of %{shot_group_count} shots",
                    shot_group_count: @shot_group.count
                  )
                }
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
