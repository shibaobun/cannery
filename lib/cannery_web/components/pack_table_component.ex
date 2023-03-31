defmodule CanneryWeb.Components.PackTableComponent do
  @moduledoc """
  A component that displays a list of packs
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo.Pack, ComparableDate}
  alias Cannery.{ActivityLog, Ammo, Containers}
  alias CanneryWeb.Components.TableComponent
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:packs) => [Pack.t()],
            required(:show_used) => boolean(),
            optional(:type) => Rendered.t(),
            optional(:range) => Rendered.t(),
            optional(:container) => Rendered.t(),
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{id: _id, packs: _pack, current_user: _current_user, show_used: _show_used} = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:type, fn -> [] end)
      |> assign_new(:range, fn -> [] end)
      |> assign_new(:container, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)
      |> display_packs()

    {:ok, socket}
  end

  defp display_packs(
         %{
           assigns: %{
             packs: packs,
             current_user: current_user,
             type: type,
             range: range,
             container: container,
             actions: actions,
             show_used: show_used
           }
         } = socket
       ) do
    lot_number_used = packs |> Enum.any?(fn %{lot_number: lot_number} -> !!lot_number end)
    price_paid_used = packs |> Enum.any?(fn %{price_paid: price_paid} -> !!price_paid end)

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
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Lot number"), key: :lot_number},
        lot_number_used
      )
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("CPR"), key: :cpr},
        price_paid_used
      )
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Price paid"), key: :price_paid},
        price_paid_used
      )
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
        %{label: gettext("Type"), key: :type},
        type != []
      )

    containers =
      packs
      |> Enum.map(fn %{container_id: container_id} -> container_id end)
      |> Containers.get_containers(current_user)

    extra_data = %{
      current_user: current_user,
      type: type,
      columns: columns,
      container: container,
      containers: containers,
      original_counts: Ammo.get_original_counts(packs, current_user),
      cprs: Ammo.get_cprs(packs, current_user),
      last_used_dates: ActivityLog.get_last_used_dates(packs, current_user),
      percentages_remaining: Ammo.get_percentages_remaining(packs, current_user),
      actions: actions,
      range: range
    }

    rows =
      packs
      |> Enum.map(fn pack ->
        pack |> get_row_data_for_pack(extra_data)
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

  @spec get_row_data_for_pack(Pack.t(), additional_data :: map()) :: map()
  defp get_row_data_for_pack(pack, %{columns: columns} = additional_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_value_for_key(key, pack, additional_data)}
    end)
  end

  @spec get_value_for_key(atom(), Pack.t(), additional_data :: map()) ::
          any() | {any(), Rendered.t()}
  defp get_value_for_key(
         :type,
         %{type: %{name: type_name} = type},
         %{type: type_block}
       ) do
    assigns = %{type: type, type_block: type_block}

    {type_name,
     ~H"""
     <%= render_slot(@type_block, @type) %>
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

  defp get_value_for_key(:used_up_on, %{id: pack_id}, %{last_used_dates: last_used_dates}) do
    last_used_date = last_used_dates |> Map.get(pack_id)
    assigns = %{id: pack_id, last_used_date: last_used_date}

    {last_used_date,
     ~H"""
     <%= if @last_used_date do %>
       <.date id={"#{@id}-last-used-date"} date={@last_used_date} />
     <% else %>
       <%= gettext("Never used") %>
     <% end %>
     """}
  end

  defp get_value_for_key(:range, %{staged: staged} = pack, %{range: range}) do
    assigns = %{range: range, pack: pack}

    {staged,
     ~H"""
     <%= render_slot(@range, @pack) %>
     """}
  end

  defp get_value_for_key(
         :remaining,
         %{id: pack_id},
         %{percentages_remaining: percentages_remaining}
       ) do
    percentage = Map.fetch!(percentages_remaining, pack_id)
    {percentage, gettext("%{percentage}%", percentage: percentage)}
  end

  defp get_value_for_key(:actions, pack, %{actions: actions}) do
    assigns = %{actions: actions, pack: pack}

    ~H"""
    <%= render_slot(@actions, @pack) %>
    """
  end

  defp get_value_for_key(:container, %{container: nil}, _additional_data), do: {nil, nil}

  defp get_value_for_key(
         :container,
         %{container_id: container_id} = pack,
         %{container: container_block, containers: containers}
       ) do
    container = %{name: container_name} = Map.fetch!(containers, container_id)

    assigns = %{
      container: container,
      container_block: container_block,
      pack: pack
    }

    {container_name,
     ~H"""
     <%= render_slot(@container_block, {@pack, @container}) %>
     """}
  end

  defp get_value_for_key(
         :original_count,
         %{id: pack_id},
         %{original_counts: original_counts}
       ) do
    Map.fetch!(original_counts, pack_id)
  end

  defp get_value_for_key(:cpr, %{price_paid: nil}, _additional_data),
    do: {0, gettext("No cost information")}

  defp get_value_for_key(:cpr, %{id: pack_id}, %{cprs: cprs}) do
    amount = Map.fetch!(cprs, pack_id)
    {amount, gettext("$%{amount}", amount: display_currency(amount))}
  end

  defp get_value_for_key(:count, %{count: count}, _additional_data),
    do: if(count == 0, do: {0, gettext("Empty")}, else: count)

  defp get_value_for_key(key, pack, _additional_data), do: pack |> Map.get(key)

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
end
