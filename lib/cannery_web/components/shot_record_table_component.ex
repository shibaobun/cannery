defmodule CanneryWeb.Components.ShotRecordTableComponent do
  @moduledoc """
  A component that displays a list of shot records
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog.ShotRecord, Ammo, ComparableDate}
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            optional(:shot_records) => [ShotRecord.t()],
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{id: _id, shot_records: _shot_records, current_user: _current_user} = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> display_shot_records()

    {:ok, socket}
  end

  defp display_shot_records(
         %{
           assigns: %{
             shot_records: shot_records,
             current_user: current_user,
             actions: actions
           }
         } = socket
       ) do
    columns = [
      %{label: gettext("Ammo"), key: :name},
      %{label: gettext("Rounds shot"), key: :count},
      %{label: gettext("Notes"), key: :notes},
      %{label: gettext("Date"), key: :date, type: ComparableDate},
      %{label: gettext("Actions"), key: :actions, sortable: false}
    ]

    packs =
      shot_records
      |> Enum.map(fn %{pack_id: pack_id} -> pack_id end)
      |> Ammo.get_packs(current_user)

    extra_data = %{current_user: current_user, actions: actions, packs: packs}

    rows =
      shot_records
      |> Enum.map(fn shot_record ->
        shot_record |> get_row_data_for_shot_record(columns, extra_data)
      end)

    socket
    |> assign(
      columns: columns,
      rows: rows
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="w-full">
      <.live_component
        module={CanneryWeb.Components.TableComponent}
        id={"table-#{@id}"}
        columns={@columns}
        rows={@rows}
        initial_key={:date}
        initial_sort_mode={:desc}
      />
    </div>
    """
  end

  @spec get_row_data_for_shot_record(ShotRecord.t(), columns :: [map()], extra_data :: map()) ::
          map()
  defp get_row_data_for_shot_record(shot_record, columns, extra_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_row_value(key, shot_record, extra_data)}
    end)
  end

  defp get_row_value(:name, %{pack_id: pack_id}, %{packs: packs}) do
    assigns = %{pack: pack = Map.fetch!(packs, pack_id)}

    {pack.type.name,
     ~H"""
     <.link navigate={Routes.pack_show_path(Endpoint, :show, @pack)} class="link">
       <%= @pack.type.name %>
     </.link>
     """}
  end

  defp get_row_value(:date, %{date: date} = assigns, _extra_data) do
    {date,
     ~H"""
     <.date id={"#{@id}-date"} date={@date} />
     """}
  end

  defp get_row_value(:actions, shot_record, %{actions: actions}) do
    assigns = %{actions: actions, shot_record: shot_record}

    ~H"""
    <%= render_slot(@actions, @shot_record) %>
    """
  end

  defp get_row_value(key, shot_record, _extra_data), do: shot_record |> Map.get(key)
end
