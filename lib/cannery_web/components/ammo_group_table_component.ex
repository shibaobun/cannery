defmodule CanneryWeb.Components.AmmoGroupTableComponent do
  @moduledoc """
  A component that displays a list of ammo groups
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo.AmmoGroup, ComparableDate}
  alias Cannery.{ActivityLog, Ammo, Containers}
  alias CanneryWeb.Components.TableComponent
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:ammo_groups) => [AmmoGroup.t()],
            required(:show_used) => boolean(),
            optional(:ammo_type) => Rendered.t(),
            optional(:range) => Rendered.t(),
            optional(:container) => Rendered.t(),
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{id: _id, ammo_groups: _ammo_group, current_user: _current_user, show_used: _show_used} =
          assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:ammo_type, fn -> [] end)
      |> assign_new(:range, fn -> [] end)
      |> assign_new(:container, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)
      |> display_ammo_groups()

    {:ok, socket}
  end

  defp display_ammo_groups(
         %{
           assigns: %{
             ammo_groups: ammo_groups,
             current_user: current_user,
             ammo_type: ammo_type,
             range: range,
             container: container,
             actions: actions,
             show_used: show_used
           }
         } = socket
       ) do
    columns =
      []
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Actions"), key: :actions, sortable: false},
        actions != []
      )
      |> TableComponent.maybe_compose_columns(%{
        label: gettext("Last used on"),
        key: :used_up_on,
        type: ComparableDate
      })
      |> TableComponent.maybe_compose_columns(%{
        label: gettext("Purchased on"),
        key: :purchased_on,
        type: ComparableDate
      })
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Container"), key: :container},
        container != []
      )
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Range"), key: :range},
        range != []
      )
      |> TableComponent.maybe_compose_columns(%{label: gettext("CPR"), key: :cpr})
      |> TableComponent.maybe_compose_columns(%{label: gettext("Price paid"), key: :price_paid})
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("% left"), key: :remaining},
        show_used
      )
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Original Count"), key: :original_count},
        show_used
      )
      |> TableComponent.maybe_compose_columns(%{
        label: if(show_used, do: gettext("Current Count"), else: gettext("Count")),
        key: :count
      })
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Ammo type"), key: :ammo_type},
        ammo_type != []
      )

    containers =
      ammo_groups
      |> Enum.map(fn %{container_id: container_id} -> container_id end)
      |> Containers.get_containers(current_user)

    extra_data = %{
      current_user: current_user,
      ammo_type: ammo_type,
      columns: columns,
      container: container,
      containers: containers,
      original_counts: Ammo.get_original_counts(ammo_groups, current_user),
      cprs: Ammo.get_cprs(ammo_groups, current_user),
      last_used_dates: ActivityLog.get_last_used_dates(ammo_groups, current_user),
      percentages_remaining: Ammo.get_percentages_remaining(ammo_groups, current_user),
      actions: actions,
      range: range
    }

    rows =
      ammo_groups
      |> Enum.map(fn ammo_group ->
        ammo_group |> get_row_data_for_ammo_group(extra_data)
      end)

    socket |> assign(columns: columns, rows: rows)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="w-full">
      <.live_component module={TableComponent} id={"table-#{@id}"} columns={@columns} rows={@rows} />
    </div>
    """
  end

  @spec get_row_data_for_ammo_group(AmmoGroup.t(), additional_data :: map()) :: map()
  defp get_row_data_for_ammo_group(ammo_group, %{columns: columns} = additional_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_value_for_key(key, ammo_group, additional_data)}
    end)
  end

  @spec get_value_for_key(atom(), AmmoGroup.t(), additional_data :: map()) ::
          any() | {any(), Rendered.t()}
  defp get_value_for_key(
         :ammo_type,
         %{ammo_type: %{name: ammo_type_name} = ammo_type},
         %{ammo_type: ammo_type_block}
       ) do
    assigns = %{ammo_type: ammo_type, ammo_type_block: ammo_type_block}

    {ammo_type_name,
     ~H"""
     <%= render_slot(@ammo_type_block, @ammo_type) %>
     """}
  end

  defp get_value_for_key(:price_paid, %{price_paid: nil}, _additional_data),
    do: {0, gettext("No cost information")}

  defp get_value_for_key(:price_paid, %{price_paid: price_paid}, _additional_data),
    do: {price_paid, gettext("$%{amount}", amount: display_currency(price_paid))}

  defp get_value_for_key(:purchased_on, %{purchased_on: purchased_on} = assigns, _additional_data) do
    {purchased_on,
     ~H"""
     <.date id={"#{@id}-purchased-on"} date={@purchased_on} />
     """}
  end

  defp get_value_for_key(:used_up_on, %{id: ammo_group_id}, %{last_used_dates: last_used_dates}) do
    last_used_date = last_used_dates |> Map.get(ammo_group_id)
    assigns = %{id: ammo_group_id, last_used_date: last_used_date}

    {last_used_date,
     ~H"""
     <%= if @last_used_date do %>
       <.date id={"#{@id}-last-used-date"} date={@last_used_date} />
     <% else %>
       <%= gettext("Never used") %>
     <% end %>
     """}
  end

  defp get_value_for_key(:range, %{staged: staged} = ammo_group, %{range: range}) do
    assigns = %{range: range, ammo_group: ammo_group}

    {staged,
     ~H"""
     <%= render_slot(@range, @ammo_group) %>
     """}
  end

  defp get_value_for_key(
         :remaining,
         %{id: ammo_group_id},
         %{percentages_remaining: percentages_remaining}
       ) do
    percentage = Map.fetch!(percentages_remaining, ammo_group_id)
    {percentage, gettext("%{percentage}%", percentage: percentage)}
  end

  defp get_value_for_key(:actions, ammo_group, %{actions: actions}) do
    assigns = %{actions: actions, ammo_group: ammo_group}

    ~H"""
    <%= render_slot(@actions, @ammo_group) %>
    """
  end

  defp get_value_for_key(:container, %{container: nil}, _additional_data), do: {nil, nil}

  defp get_value_for_key(
         :container,
         %{container_id: container_id} = ammo_group,
         %{container: container_block, containers: containers}
       ) do
    container = %{name: container_name} = Map.fetch!(containers, container_id)

    assigns = %{
      container: container,
      container_block: container_block,
      ammo_group: ammo_group
    }

    {container_name,
     ~H"""
     <%= render_slot(@container_block, {@ammo_group, @container}) %>
     """}
  end

  defp get_value_for_key(
         :original_count,
         %{id: ammo_group_id},
         %{original_counts: original_counts}
       ) do
    Map.fetch!(original_counts, ammo_group_id)
  end

  defp get_value_for_key(:cpr, %{price_paid: nil}, _additional_data),
    do: {0, gettext("No cost information")}

  defp get_value_for_key(:cpr, %{id: ammo_group_id}, %{cprs: cprs}) do
    amount = Map.fetch!(cprs, ammo_group_id)
    {amount, gettext("$%{amount}", amount: display_currency(amount))}
  end

  defp get_value_for_key(:count, %{count: count}, _additional_data),
    do: if(count == 0, do: {0, gettext("Empty")}, else: count)

  defp get_value_for_key(key, ammo_group, _additional_data), do: ammo_group |> Map.get(key)

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
end
