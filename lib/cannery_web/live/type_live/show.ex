defmodule CanneryWeb.TypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.Type
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, Ammo, Ammo.Type, Containers}

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, socket |> assign(show_used: false, view_table: true)}

  @impl true
  def handle_params(%{"id" => id}, _params, socket) do
    {:noreply, socket |> display_type(id)}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{type: type, current_user: current_user}} = socket
      ) do
    %{name: type_name} = type |> Ammo.delete_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: type_name)
    redirect_to = ~p"/catalog"

    {:noreply, socket |> put_flash(:info, prompt) |> push_navigate(to: redirect_to)}
  end

  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> display_type()}
  end

  def handle_event("toggle_table", _params, %{assigns: %{view_table: view_table}} = socket) do
    {:noreply, socket |> assign(:view_table, !view_table)}
  end

  defp display_type(
         %{assigns: %{live_action: live_action, current_user: current_user, show_used: show_used}} =
           socket,
         %Type{id: type_id, name: type_name} = type
       ) do
    custom_fields? =
      fields_to_display(type)
      |> Enum.any?(fn %{key: field, type: column_type} ->
        default_value =
          case column_type do
            :boolean -> false
            _other_type -> nil
          end

        type |> Map.get(field) != default_value
      end)

    packs = Ammo.list_packs(current_user, type_id: type_id, show_used: show_used)

    [
      original_counts,
      used_packs_count,
      historical_packs_count,
      used_rounds,
      historical_round_count
    ] =
      if show_used do
        [
          packs |> Ammo.get_original_counts(current_user),
          Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used),
          Ammo.get_packs_count(current_user, type_id: type.id, show_used: true),
          type |> ActivityLog.get_used_count_for_type(current_user),
          type |> Ammo.get_historical_count_for_type(current_user)
        ]
      else
        [nil, nil, nil, nil, nil]
      end

    page_title =
      case live_action do
        :show -> type_name
        :edit -> gettext("Edit %{type_name}", type_name: type_name)
      end

    containers =
      packs
      |> Enum.map(fn %{container_id: container_id} -> container_id end)
      |> Containers.get_containers(current_user)

    socket
    |> assign(
      page_title: page_title,
      type: type,
      packs: packs,
      containers: containers,
      cprs: packs |> Ammo.get_cprs(current_user),
      last_used_dates: packs |> ActivityLog.get_last_used_dates(current_user),
      avg_cost_per_round: type |> Ammo.get_average_cost_for_type(current_user),
      rounds: type |> Ammo.get_round_count_for_type(current_user),
      original_counts: original_counts,
      used_rounds: used_rounds,
      historical_round_count: historical_round_count,
      packs_count: Ammo.get_packs_count(current_user, type_id: type.id),
      used_packs_count: used_packs_count,
      historical_packs_count: historical_packs_count,
      fields_to_display: fields_to_display(type),
      custom_fields?: custom_fields?
    )
  end

  defp display_type(%{assigns: %{current_user: current_user}} = socket, type_id) do
    socket |> display_type(Ammo.get_type!(type_id, current_user))
  end

  defp display_type(%{assigns: %{type: type}} = socket) do
    socket |> display_type(type)
  end

  defp fields_to_display(%Type{class: class}) do
    [
      %{label: gettext("Cartridge:"), key: :cartridge, type: :string},
      %{
        label: if(class == :shotgun, do: gettext("Gauge:"), else: gettext("Caliber:")),
        key: :caliber,
        type: :string
      },
      %{label: gettext("Unfired length:"), key: :unfired_length, type: :string},
      %{label: gettext("Brass height:"), key: :brass_height, type: :string},
      %{label: gettext("Chamber size:"), key: :chamber_size, type: :string},
      %{label: gettext("Grains:"), key: :grains, type: :string},
      %{label: gettext("Bullet type:"), key: :bullet_type, type: :string},
      %{label: gettext("Bullet core:"), key: :bullet_core, type: :string},
      %{label: gettext("Jacket type:"), key: :jacket_type, type: :string},
      %{label: gettext("Case material:"), key: :case_material, type: :string},
      %{label: gettext("Wadding:"), key: :wadding, type: :string},
      %{label: gettext("Shot type:"), key: :shot_type, type: :string},
      %{label: gettext("Shot material:"), key: :shot_material, type: :string},
      %{label: gettext("Shot size:"), key: :shot_size, type: :string},
      %{label: gettext("Load grains:"), key: :load_grains, type: :string},
      %{label: gettext("Shot charge weight:"), key: :shot_charge_weight, type: :string},
      %{label: gettext("Powder type:"), key: :powder_type, type: :string},
      %{
        label: gettext("Powder grains per charge:"),
        key: :powder_grains_per_charge,
        type: :string
      },
      %{label: gettext("Pressure:"), key: :pressure, type: :string},
      %{label: gettext("Dram equivalent:"), key: :dram_equivalent, type: :string},
      %{label: gettext("Muzzle velocity:"), key: :muzzle_velocity, type: :string},
      %{label: gettext("Primer type:"), key: :primer_type, type: :string},
      %{label: gettext("Firing type:"), key: :firing_type, type: :string},
      %{label: gettext("Tracer:"), key: :tracer, type: :boolean},
      %{label: gettext("Incendiary:"), key: :incendiary, type: :boolean},
      %{label: gettext("Blank:"), key: :blank, type: :boolean},
      %{label: gettext("Corrosive:"), key: :corrosive, type: :boolean},
      %{label: gettext("Manufacturer:"), key: :manufacturer, type: :string},
      %{label: gettext("UPC:"), key: :upc, type: :string}
    ]
  end

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
end
