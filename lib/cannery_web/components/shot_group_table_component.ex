defmodule CanneryWeb.Components.ShotGroupTableComponent do
  @moduledoc """
  A component that displays a list of shot groups
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Repo}
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
      %{label: gettext("Date"), key: :date},
      %{label: nil, key: :actions, sortable: false}
    ]

    extra_data = %{current_user: current_user, actions: actions}

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
    shot_group = shot_group |> Repo.preload(ammo_group: :ammo_type)

    columns
    |> Map.new(fn %{key: key} ->
      {key, get_row_value(key, shot_group, extra_data)}
    end)
  end

  defp get_row_value(
         :name,
         %{ammo_group: %{ammo_type: %{name: ammo_type_name} = ammo_group}},
         _extra_data
       ) do
    assigns = %{ammo_group: ammo_group, ammo_type_name: ammo_type_name}

    name_block = ~H"""
    <.link navigate={Routes.ammo_group_show_path(Endpoint, :show, @ammo_group)} class="link">
      <%= @ammo_type_name %>
    </.link>
    """

    {ammo_type_name, name_block}
  end

  defp get_row_value(:date, %{date: date}, _extra_data), do: date |> display_date()

  defp get_row_value(:actions, shot_group, %{actions: actions}) do
    assigns = %{actions: actions, shot_group: shot_group}

    ~H"""
    <%= render_slot(@actions, @shot_group) %>
    """
  end

  defp get_row_value(key, shot_group, _extra_data), do: shot_group |> Map.get(key)
end
