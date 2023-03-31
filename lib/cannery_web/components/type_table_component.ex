defmodule CanneryWeb.Components.TypeTableComponent do
  @moduledoc """
  A component that displays a list of types
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, Ammo, Ammo.Type}
  alias CanneryWeb.Components.TableComponent
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            optional(:class) => Type.class() | nil,
            optional(:show_used) => boolean(),
            optional(:types) => [Type.t()],
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, types: _types, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:show_used, fn -> false end)
      |> assign_new(:class, fn -> :all end)
      |> assign_new(:actions, fn -> [] end)
      |> display_types()

    {:ok, socket}
  end

  defp display_types(
         %{
           assigns: %{
             types: types,
             current_user: current_user,
             show_used: show_used,
             class: class,
             actions: actions
           }
         } = socket
       ) do
    filtered_columns =
      [
        %{label: gettext("Cartridge"), key: :cartridge, type: :string},
        %{
          label: if(class == :shotgun, do: gettext("Gauge"), else: gettext("Caliber")),
          key: :caliber,
          type: :string
        },
        %{label: gettext("Unfired shell length"), key: :unfired_length, type: :string},
        %{label: gettext("Brass height"), key: :brass_height, type: :string},
        %{label: gettext("Chamber size"), key: :chamber_size, type: :string},
        %{label: gettext("Chamber size"), key: :chamber_size, type: :string},
        %{label: gettext("Grains"), key: :grains, type: :string},
        %{label: gettext("Bullet type"), key: :bullet_type, type: :string},
        %{
          label: if(class == :shotgun, do: gettext("Slug core"), else: gettext("Bullet core")),
          key: :bullet_core,
          type: :string
        },
        %{label: gettext("Jacket type"), key: :jacket_type, type: :string},
        %{label: gettext("Case material"), key: :case_material, type: :string},
        %{label: gettext("Wadding"), key: :wadding, type: :string},
        %{label: gettext("Shot type"), key: :shot_type, type: :string},
        %{label: gettext("Shot material"), key: :shot_material, type: :string},
        %{label: gettext("Shot size"), key: :shot_size, type: :string},
        %{label: gettext("Load grains"), key: :load_grains, type: :string},
        %{label: gettext("Shot charge weight"), key: :shot_charge_weight, type: :string},
        %{label: gettext("Powder type"), key: :powder_type, type: :string},
        %{
          label: gettext("Powder grains per charge"),
          key: :powder_grains_per_charge,
          type: :string
        },
        %{label: gettext("Pressure"), key: :pressure, type: :string},
        %{label: gettext("Dram equivalent"), key: :dram_equivalent, type: :string},
        %{label: gettext("Muzzle velocity"), key: :muzzle_velocity, type: :string},
        %{label: gettext("Primer type"), key: :primer_type, type: :string},
        %{label: gettext("Firing type"), key: :firing_type, type: :string},
        %{label: gettext("Tracer"), key: :tracer, type: :atom},
        %{label: gettext("Incendiary"), key: :incendiary, type: :atom},
        %{label: gettext("Blank"), key: :blank, type: :atom},
        %{label: gettext("Corrosive"), key: :corrosive, type: :atom},
        %{label: gettext("Manufacturer"), key: :manufacturer, type: :string}
      ]
      |> Enum.filter(fn %{key: key, type: type} ->
        # remove columns if all values match defaults
        default_value = if type == :atom, do: false, else: nil

        types
        |> Enum.any?(fn type -> Map.get(type, key, default_value) != default_value end)
      end)

    columns =
      [%{label: gettext("Actions"), key: "actions", type: :actions, sortable: false}]
      |> TableComponent.maybe_compose_columns(%{
        label: gettext("Average CPR"),
        key: :avg_price_paid,
        type: :avg_price_paid
      })
      |> TableComponent.maybe_compose_columns(
        %{
          label: gettext("Total ever packs"),
          key: :historical_pack_count,
          type: :historical_pack_count
        },
        show_used
      )
      |> TableComponent.maybe_compose_columns(
        %{
          label: gettext("Used packs"),
          key: :used_pack_count,
          type: :used_pack_count
        },
        show_used
      )
      |> TableComponent.maybe_compose_columns(%{
        label: gettext("Packs"),
        key: :ammo_count,
        type: :ammo_count
      })
      |> TableComponent.maybe_compose_columns(
        %{
          label: gettext("Total ever rounds"),
          key: :historical_round_count,
          type: :historical_round_count
        },
        show_used
      )
      |> TableComponent.maybe_compose_columns(
        %{
          label: gettext("Used rounds"),
          key: :used_round_count,
          type: :used_round_count
        },
        show_used
      )
      |> TableComponent.maybe_compose_columns(%{
        label: gettext("Rounds"),
        key: :round_count,
        type: :round_count
      })
      |> TableComponent.maybe_compose_columns(filtered_columns)
      |> TableComponent.maybe_compose_columns(
        %{label: gettext("Class"), key: :class, type: :atom},
        class in [:all, nil]
      )
      |> TableComponent.maybe_compose_columns(%{label: gettext("Name"), key: :name, type: :name})

    round_counts = types |> Ammo.get_round_count_for_types(current_user)
    packs_count = types |> Ammo.get_packs_count_for_types(current_user)
    average_costs = types |> Ammo.get_average_cost_for_types(current_user)

    [used_counts, historical_round_counts, historical_pack_counts, used_pack_counts] =
      if show_used do
        [
          types |> ActivityLog.get_used_count_for_types(current_user),
          types |> Ammo.get_historical_count_for_types(current_user),
          types |> Ammo.get_packs_count_for_types(current_user, true),
          types |> Ammo.get_used_packs_count_for_types(current_user)
        ]
      else
        [nil, nil, nil, nil]
      end

    extra_data = %{
      actions: actions,
      current_user: current_user,
      used_counts: used_counts,
      round_counts: round_counts,
      historical_round_counts: historical_round_counts,
      packs_count: packs_count,
      used_pack_counts: used_pack_counts,
      historical_pack_counts: historical_pack_counts,
      average_costs: average_costs
    }

    rows =
      types
      |> Enum.map(fn type ->
        type |> get_type_values(columns, extra_data)
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

  defp get_type_values(type, columns, extra_data) do
    columns
    |> Map.new(fn %{key: key, type: column_type} ->
      {key, get_type_value(column_type, key, type, extra_data)}
    end)
  end

  defp get_type_value(:atom, key, type, _other_data),
    do: type |> Map.get(key) |> humanize()

  defp get_type_value(:round_count, _key, %{id: type_id}, %{round_counts: round_counts}),
    do: Map.get(round_counts, type_id, 0)

  defp get_type_value(
         :historical_round_count,
         _key,
         %{id: type_id},
         %{historical_round_counts: historical_round_counts}
       ) do
    Map.get(historical_round_counts, type_id, 0)
  end

  defp get_type_value(
         :used_round_count,
         _key,
         %{id: type_id},
         %{used_counts: used_counts}
       ) do
    Map.get(used_counts, type_id, 0)
  end

  defp get_type_value(
         :historical_pack_count,
         _key,
         %{id: type_id},
         %{historical_pack_counts: historical_pack_counts}
       ) do
    Map.get(historical_pack_counts, type_id, 0)
  end

  defp get_type_value(
         :used_pack_count,
         _key,
         %{id: type_id},
         %{used_pack_counts: used_pack_counts}
       ) do
    Map.get(used_pack_counts, type_id, 0)
  end

  defp get_type_value(:ammo_count, _key, %{id: type_id}, %{packs_count: packs_count}),
    do: Map.get(packs_count, type_id)

  defp get_type_value(
         :avg_price_paid,
         _key,
         %{id: type_id},
         %{average_costs: average_costs}
       ) do
    case Map.get(average_costs, type_id) do
      nil -> {0, gettext("No cost information")}
      count -> {count, gettext("$%{amount}", amount: display_currency(count))}
    end
  end

  defp get_type_value(:name, _key, %{name: type_name} = type, _other_data) do
    assigns = %{type: type}

    {type_name,
     ~H"""
     <.link navigate={Routes.type_show_path(Endpoint, :show, @type)} class="link">
       <%= @type.name %>
     </.link>
     """}
  end

  defp get_type_value(:actions, _key, type, %{actions: actions}) do
    assigns = %{actions: actions, type: type}

    ~H"""
    <%= render_slot(@actions, @type) %>
    """
  end

  defp get_type_value(nil, _key, _type, _other_data), do: nil

  defp get_type_value(_other, key, type, _other_data), do: type |> Map.get(key)

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
end
