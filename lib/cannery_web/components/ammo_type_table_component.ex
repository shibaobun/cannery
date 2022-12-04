defmodule CanneryWeb.Components.AmmoTypeTableComponent do
  @moduledoc """
  A component that displays a list of ammo type
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoType}
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
              key: :used_ammo_count,
              type: :used_ammo_count
            },
            %{
              label: gettext("Total ever packs"),
              key: :historical_ammo_count,
              type: :historical_ammo_count
            }
          ]
        else
          []
        end
      )
      |> Kernel.++([
        %{label: gettext("Average CPR"), key: :avg_price_paid, type: :avg_price_paid},
        %{label: nil, key: "actions", type: :actions, sortable: false}
      ])

    extra_data = %{actions: actions, current_user: current_user}

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

  defp get_ammo_type_value(:round_count, _key, ammo_type, %{current_user: current_user}),
    do: ammo_type |> Ammo.get_round_count_for_ammo_type(current_user)

  defp get_ammo_type_value(:historical_round_count, _key, ammo_type, %{current_user: current_user}),
       do: ammo_type |> Ammo.get_historical_count_for_ammo_type(current_user)

  defp get_ammo_type_value(:used_round_count, _key, ammo_type, %{current_user: current_user}),
    do: ammo_type |> Ammo.get_used_count_for_ammo_type(current_user)

  defp get_ammo_type_value(:historical_ammo_count, _key, ammo_type, %{current_user: current_user}),
    do: ammo_type |> Ammo.get_ammo_groups_count_for_type(current_user, true)

  defp get_ammo_type_value(:used_ammo_count, _key, ammo_type, %{current_user: current_user}),
    do: ammo_type |> Ammo.get_used_ammo_groups_count_for_type(current_user)

  defp get_ammo_type_value(:ammo_count, _key, ammo_type, %{current_user: current_user}),
    do: ammo_type |> Ammo.get_ammo_groups_count_for_type(current_user)

  defp get_ammo_type_value(:avg_price_paid, _key, ammo_type, %{current_user: current_user}) do
    case ammo_type |> Ammo.get_average_cost_for_ammo_type!(current_user) do
      nil -> gettext("No cost information")
      count -> gettext("$%{amount}", amount: count |> :erlang.float_to_binary(decimals: 2))
    end
  end

  defp get_ammo_type_value(:name, _key, ammo_type, _other_data) do
    assigns = %{ammo_type: ammo_type}

    ~H"""
    <.link
      navigate={Routes.ammo_type_show_path(Endpoint, :show, @ammo_type)}
      class="link"
      data-qa={"view-name-#{@ammo_type.id}"}
    >
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
end
