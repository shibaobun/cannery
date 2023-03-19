defmodule CanneryWeb.Components.AmmoTypeTableComponent do
  @moduledoc """
  A component that displays a list of ammo type
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, Ammo, Ammo.AmmoType}
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            optional(:show_used) => boolean(),
            optional(:ammo_types) => [AmmoType.t()],
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, ammo_types: _ammo_types, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:show_used, fn -> false end)
      |> assign_new(:actions, fn -> [] end)
      |> display_ammo_types()

    {:ok, socket}
  end

  defp display_ammo_types(
         %{
           assigns: %{
             ammo_types: ammo_types,
             current_user: current_user,
             show_used: show_used,
             actions: actions
           }
         } = socket
       ) do
    columns =
      [
        %{label: gettext("Name"), key: :name, type: :name},
        %{label: gettext("Bullet type"), key: :bullet_type, type: :string},
        %{label: gettext("Bullet core"), key: :bullet_core, type: :string},
        %{label: gettext("Cartridge"), key: :cartridge, type: :string},
        %{label: gettext("Caliber"), key: :caliber, type: :string},
        %{label: gettext("Case material"), key: :case_material, type: :string},
        %{label: gettext("Jacket type"), key: :jacket_type, type: :string},
        %{label: gettext("Muzzle velocity"), key: :muzzle_velocity, type: :string},
        %{label: gettext("Powder type"), key: :powder_type, type: :string},
        %{
          label: gettext("Powder grains per charge"),
          key: :powder_grains_per_charge,
          type: :string
        },
        %{label: gettext("Grains"), key: :grains, type: :string},
        %{label: gettext("Pressure"), key: :pressure, type: :string},
        %{label: gettext("Primer type"), key: :primer_type, type: :string},
        %{label: gettext("Firing type"), key: :firing_type, type: :string},
        %{label: gettext("Tracer"), key: :tracer, type: :boolean},
        %{label: gettext("Incendiary"), key: :incendiary, type: :boolean},
        %{label: gettext("Blank"), key: :blank, type: :boolean},
        %{label: gettext("Corrosive"), key: :corrosive, type: :boolean},
        %{label: gettext("Manufacturer"), key: :manufacturer, type: :string},
        %{label: gettext("UPC"), key: "upc", type: :string}
      ]
      |> Enum.filter(fn %{key: key, type: type} ->
        # remove columns if all values match defaults
        default_value = if type == :boolean, do: false, else: nil

        ammo_types
        |> Enum.any?(fn ammo_type ->
          not (ammo_type |> Map.get(key) == default_value)
        end)
      end)
      |> Kernel.++([
        %{label: gettext("Rounds"), key: :round_count, type: :round_count}
      ])
      |> Kernel.++(
        if show_used do
          [
            %{
              label: gettext("Used rounds"),
              key: :used_round_count,
              type: :used_round_count
            },
            %{
              label: gettext("Total ever rounds"),
              key: :historical_round_count,
              type: :historical_round_count
            }
          ]
        else
          []
        end
      )
      |> Kernel.++([%{label: gettext("Packs"), key: :ammo_count, type: :ammo_count}])
      |> Kernel.++(
        if show_used do
          [
            %{
              label: gettext("Used packs"),
              key: :used_pack_count,
              type: :used_pack_count
            },
            %{
              label: gettext("Total ever packs"),
              key: :historical_pack_count,
              type: :historical_pack_count
            }
          ]
        else
          []
        end
      )
      |> Kernel.++([
        %{label: gettext("Average CPR"), key: :avg_price_paid, type: :avg_price_paid},
        %{label: gettext("Actions"), key: "actions", type: :actions, sortable: false}
      ])

    round_counts = ammo_types |> Ammo.get_round_count_for_ammo_types(current_user)
    packs_count = ammo_types |> Ammo.get_ammo_groups_count_for_types(current_user)
    average_costs = ammo_types |> Ammo.get_average_cost_for_ammo_types(current_user)

    [used_counts, historical_round_counts, historical_pack_counts, used_pack_counts] =
      if show_used do
        [
          ammo_types |> ActivityLog.get_used_count_for_ammo_types(current_user),
          ammo_types |> Ammo.get_historical_count_for_ammo_types(current_user),
          ammo_types |> Ammo.get_ammo_groups_count_for_types(current_user, true),
          ammo_types |> Ammo.get_used_ammo_groups_count_for_types(current_user)
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
      ammo_types
      |> Enum.map(fn ammo_type ->
        ammo_type |> get_ammo_type_values(columns, extra_data)
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

  defp get_ammo_type_values(ammo_type, columns, extra_data) do
    columns
    |> Map.new(fn %{key: key, type: type} ->
      {key, get_ammo_type_value(type, key, ammo_type, extra_data)}
    end)
  end

  defp get_ammo_type_value(:boolean, key, ammo_type, _other_data),
    do: ammo_type |> Map.get(key) |> humanize()

  defp get_ammo_type_value(:round_count, _key, %{id: ammo_type_id}, %{round_counts: round_counts}),
    do: Map.get(round_counts, ammo_type_id)

  defp get_ammo_type_value(
         :historical_round_count,
         _key,
         %{id: ammo_type_id},
         %{historical_round_counts: historical_round_counts}
       ) do
    Map.get(historical_round_counts, ammo_type_id)
  end

  defp get_ammo_type_value(
         :used_round_count,
         _key,
         %{id: ammo_type_id},
         %{used_counts: used_counts}
       ) do
    Map.get(used_counts, ammo_type_id)
  end

  defp get_ammo_type_value(
         :historical_pack_count,
         _key,
         %{id: ammo_type_id},
         %{historical_pack_counts: historical_pack_counts}
       ) do
    Map.get(historical_pack_counts, ammo_type_id)
  end

  defp get_ammo_type_value(
         :used_pack_count,
         _key,
         %{id: ammo_type_id},
         %{used_pack_counts: used_pack_counts}
       ) do
    Map.get(used_pack_counts, ammo_type_id, 0)
  end

  defp get_ammo_type_value(:ammo_count, _key, %{id: ammo_type_id}, %{packs_count: packs_count}),
    do: Map.get(packs_count, ammo_type_id)

  defp get_ammo_type_value(
         :avg_price_paid,
         _key,
         %{id: ammo_type_id},
         %{average_costs: average_costs}
       ) do
    case Map.get(average_costs, ammo_type_id) do
      nil -> gettext("No cost information")
      count -> gettext("$%{amount}", amount: display_currency(count))
    end
  end

  defp get_ammo_type_value(:name, _key, ammo_type, _other_data) do
    assigns = %{ammo_type: ammo_type}

    ~H"""
    <.link navigate={Routes.ammo_type_show_path(Endpoint, :show, @ammo_type)} class="link">
      <%= @ammo_type.name %>
    </.link>
    """
  end

  defp get_ammo_type_value(:actions, _key, ammo_type, %{actions: actions}) do
    assigns = %{actions: actions, ammo_type: ammo_type}

    ~H"""
    <%= render_slot(@actions, @ammo_type) %>
    """
  end

  defp get_ammo_type_value(nil, _key, _ammo_type, _other_data), do: nil

  defp get_ammo_type_value(_other, key, ammo_type, _other_data), do: ammo_type |> Map.get(key)

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
end
