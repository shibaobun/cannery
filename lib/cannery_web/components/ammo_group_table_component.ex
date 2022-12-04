defmodule CanneryWeb.Components.AmmoGroupTableComponent do
  @moduledoc """
  A component that displays a list of ammo groups
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoGroup, Repo}
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:ammo_groups) => [AmmoGroup.t()],
            optional(:ammo_type) => Rendered.t(),
            optional(:range) => Rendered.t(),
            optional(:container) => Rendered.t(),
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, ammo_groups: _ammo_group, current_user: _current_user} = assigns, socket) do
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
             actions: actions
           }
         } = socket
       ) do
    columns =
      if actions == [] do
        []
      else
        [%{label: nil, key: :actions, sortable: false}]
      end

    columns = [
      %{label: gettext("Purchased on"), key: :purchased_on},
      %{label: gettext("Last used on"), key: :used_up_on} | columns
    ]

    columns =
      if container == [] do
        columns
      else
        [%{label: gettext("Container"), key: :container} | columns]
      end

    columns =
      if range == [] do
        columns
      else
        [%{label: gettext("Range"), key: :range} | columns]
      end

    columns = [
      %{label: gettext("Count"), key: :count},
      %{label: gettext("Original Count"), key: :original_count},
      %{label: gettext("Price paid"), key: :price_paid},
      %{label: gettext("CPR"), key: :cpr},
      %{label: gettext("% left"), key: :remaining},
      %{label: gettext("Notes"), key: :notes}
      | columns
    ]

    columns =
      if ammo_type == [] do
        columns
      else
        [%{label: gettext("Ammo type"), key: :ammo_type} | columns]
      end

    extra_data = %{
      current_user: current_user,
      ammo_type: ammo_type,
      columns: columns,
      container: container,
      actions: actions,
      range: range
    }

    rows =
      ammo_groups
      |> Repo.preload([:ammo_type, :container])
      |> Enum.map(fn ammo_group ->
        ammo_group |> get_row_data_for_ammo_group(extra_data)
      end)

    socket |> assign(columns: columns, rows: rows)
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
      />
    </div>
    """
  end

  @spec get_row_data_for_ammo_group(AmmoGroup.t(), additional_data :: map()) :: map()
  defp get_row_data_for_ammo_group(ammo_group, %{columns: columns} = additional_data) do
    ammo_group = ammo_group |> Repo.preload([:ammo_type, :container])

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

  defp get_value_for_key(:price_paid, %{price_paid: nil}, _additional_data), do: {"", nil}

  defp get_value_for_key(:price_paid, %{price_paid: price_paid}, _additional_data),
    do: gettext("$%{amount}", amount: price_paid |> :erlang.float_to_binary(decimals: 2))

  defp get_value_for_key(:purchased_on, %{purchased_on: purchased_on}, _additional_data) do
    assigns = %{purchased_on: purchased_on}

    {purchased_on,
     ~H"""
     <%= @purchased_on |> display_date() %>
     """}
  end

  defp get_value_for_key(:used_up_on, ammo_group, _additional_data) do
    last_shot_group_date =
      case ammo_group |> Ammo.get_last_used_shot_group() do
        %{date: last_shot_group_date} -> last_shot_group_date
        _no_shot_groups -> nil
      end

    assigns = %{last_shot_group_date: last_shot_group_date}

    {last_shot_group_date,
     ~H"""
     <%= if @last_shot_group_date do %>
       <%= @last_shot_group_date |> display_date() %>
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

  defp get_value_for_key(:remaining, ammo_group, _additional_data),
    do: gettext("%{percentage}%", percentage: ammo_group |> Ammo.get_percentage_remaining())

  defp get_value_for_key(:actions, ammo_group, %{actions: actions}) do
    assigns = %{actions: actions, ammo_group: ammo_group}

    ~H"""
    <%= render_slot(@actions, @ammo_group) %>
    """
  end

  defp get_value_for_key(:container, %{container: nil}, _additional_data), do: {nil, nil}

  defp get_value_for_key(
         :container,
         %{container: %{name: container_name}} = ammo_group,
         %{container: container}
       ) do
    assigns = %{container: container, ammo_group: ammo_group}

    {container_name,
     ~H"""
     <%= render_slot(@container, @ammo_group) %>
     """}
  end

  defp get_value_for_key(:original_count, ammo_group, _additional_data),
    do: ammo_group |> Ammo.get_original_count()

  defp get_value_for_key(:cpr, %{price_paid: nil}, _additional_data),
    do: gettext("No cost information")

  defp get_value_for_key(:cpr, ammo_group, _additional_data) do
    gettext("$%{amount}",
      amount: ammo_group |> Ammo.get_cpr() |> :erlang.float_to_binary(decimals: 2)
    )
  end

  defp get_value_for_key(:count, %{count: count}, _additional_data),
    do: if(count == 0, do: gettext("Empty"), else: count)

  defp get_value_for_key(key, ammo_group, _additional_data), do: ammo_group |> Map.get(key)
end
