defmodule CanneryWeb.PackLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.Pack
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, ActivityLog.ShotRecord}
  alias Cannery.{Ammo, Ammo.Pack}
  alias Cannery.{ComparableDate, Containers}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(
        %{"id" => id, "shot_record_id" => shot_record_id},
        _url,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    shot_record = ActivityLog.get_shot_record!(shot_record_id, current_user)

    socket =
      socket
      |> assign(page_title: page_title(live_action), shot_record: shot_record)
      |> display_pack(id)

    {:noreply, socket}
  end

  def handle_params(%{"id" => id}, _url, %{assigns: %{live_action: live_action}} = socket) do
    socket =
      socket
      |> assign(page_title: page_title(live_action))
      |> display_pack(id)

    {:noreply, socket}
  end

  defp page_title(:add_shot_record), do: gettext("Record Shots")
  defp page_title(:edit_shot_record), do: gettext("Edit Shot Record")
  defp page_title(:move), do: gettext("Move Ammo")
  defp page_title(:show), do: gettext("Show Ammo")
  defp page_title(:edit), do: gettext("Edit Ammo")

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{pack: pack, current_user: current_user}} = socket
      ) do
    pack |> Ammo.delete_pack!(current_user)

    prompt = dgettext("prompts", "Ammo deleted succesfully")
    redirect_to = Routes.pack_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_navigate(to: redirect_to)}
  end

  def handle_event(
        "toggle_staged",
        _params,
        %{assigns: %{pack: pack, current_user: current_user}} = socket
      ) do
    {:ok, pack} = pack |> Ammo.update_pack(%{"staged" => !pack.staged}, current_user)

    {:noreply, socket |> display_pack(pack)}
  end

  def handle_event(
        "delete_shot_record",
        %{"id" => id},
        %{assigns: %{pack: %{id: pack_id}, current_user: current_user}} = socket
      ) do
    {:ok, _} =
      ActivityLog.get_shot_record!(id, current_user)
      |> ActivityLog.delete_shot_record(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_pack(pack_id)}
  end

  @spec display_pack(Socket.t(), Pack.t() | Pack.id()) :: Socket.t()
  defp display_pack(
         %{assigns: %{current_user: current_user}} = socket,
         %Pack{container_id: container_id} = pack
       ) do
    columns = [
      %{label: gettext("Rounds shot"), key: :count},
      %{label: gettext("Notes"), key: :notes},
      %{label: gettext("Date"), key: :date, type: ComparableDate},
      %{label: gettext("Actions"), key: :actions, sortable: false}
    ]

    shot_records = ActivityLog.list_shot_records_for_pack(pack, current_user)

    rows =
      shot_records
      |> Enum.map(fn shot_record ->
        pack |> get_table_row_for_shot_record(shot_record, columns)
      end)

    socket
    |> assign(
      pack: pack,
      original_count: Ammo.get_original_count(pack, current_user),
      percentage_remaining: Ammo.get_percentage_remaining(pack, current_user),
      container: container_id && Containers.get_container!(container_id, current_user),
      shot_records: shot_records,
      columns: columns,
      rows: rows
    )
  end

  defp display_pack(%{assigns: %{current_user: current_user}} = socket, id),
    do: display_pack(socket, Ammo.get_pack!(id, current_user))

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)

  @spec get_table_row_for_shot_record(Pack.t(), ShotRecord.t(), [map()]) :: map()
  defp get_table_row_for_shot_record(pack, %{id: id, date: date} = shot_record, columns) do
    assigns = %{pack: pack, shot_record: shot_record}

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
                patch={Routes.pack_show_path(Endpoint, :edit_shot_record, @pack, @shot_record)}
                class="text-primary-600 link"
                aria-label={
                  dgettext("actions", "Edit shot record of %{shot_record_count} shots",
                    shot_record_count: @shot_record.count
                  )
                }
              >
                <i class="fa-fw fa-lg fas fa-edit"></i>
              </.link>

              <.link
                href="#"
                class="text-primary-600 link"
                phx-click="delete_shot_record"
                phx-value-id={@shot_record.id}
                data-confirm={dgettext("prompts", "Are you sure you want to delete this shot record?")}
                aria-label={
                  dgettext("actions", "Delete shot record of %{shot_record_count} shots",
                    shot_record_count: @shot_record.count
                  )
                }
              >
                <i class="fa-fw fa-lg fas fa-trash"></i>
              </.link>
            </div>
            """

          key ->
            shot_record |> Map.get(key)
        end

      {key, value}
    end)
  end
end
