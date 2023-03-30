defmodule CanneryWeb.Components.ShotGroupTableComponent do
  @moduledoc """
  A component that displays a list of shot groups
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Ammo, ComparableDate}
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            optional(:shot_groups) => [ShotGroup.t()],
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, shot_groups: _shot_groups, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> display_shot_groups()

    {:ok, socket}
  end

  defp display_shot_groups(
         %{
           assigns: %{
             shot_groups: shot_groups,
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
      shot_groups
      |> Enum.map(fn %{pack_id: pack_id} -> pack_id end)
      |> Ammo.get_packs(current_user)

    extra_data = %{current_user: current_user, actions: actions, packs: packs}

    rows =
      shot_groups
      |> Enum.map(fn shot_group ->
        shot_group |> get_row_data_for_shot_group(columns, extra_data)
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

  @spec get_row_data_for_shot_group(ShotGroup.t(), columns :: [map()], extra_data :: map()) ::
          map()
  defp get_row_data_for_shot_group(shot_group, columns, extra_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_row_value(key, shot_group, extra_data)}
    end)
  end

  defp get_row_value(:name, %{pack_id: pack_id}, %{packs: packs}) do
    assigns = %{pack: pack = Map.fetch!(packs, pack_id)}

    {pack.ammo_type.name,
     ~H"""
     <.link navigate={Routes.pack_show_path(Endpoint, :show, @pack)} class="link">
       <%= @pack.ammo_type.name %>
     </.link>
     """}
  end

  defp get_row_value(:date, %{date: date} = assigns, _extra_data) do
    {date,
     ~H"""
     <.date id={"#{@id}-date"} date={@date} />
     """}
  end

  defp get_row_value(:actions, shot_group, %{actions: actions}) do
    assigns = %{actions: actions, shot_group: shot_group}

    ~H"""
    <%= render_slot(@actions, @shot_group) %>
    """
  end

  defp get_row_value(key, shot_group, _extra_data), do: shot_group |> Map.get(key)
end
