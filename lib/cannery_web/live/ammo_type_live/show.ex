defmodule CanneryWeb.AmmoTypeLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_view
  alias Cannery.{ActivityLog, Ammo, Ammo.AmmoType}
  alias CanneryWeb.Endpoint

  @fields_list [
    %{label: gettext("Bullet type:"), key: :bullet_type, type: :string},
    %{label: gettext("Bullet core:"), key: :bullet_core, type: :string},
    %{label: gettext("Cartridge:"), key: :cartridge, type: :string},
    %{label: gettext("Caliber:"), key: :caliber, type: :string},
    %{label: gettext("Case material:"), key: :case_material, type: :string},
    %{label: gettext("Jacket type:"), key: :jacket_type, type: :string},
    %{label: gettext("Muzzle velocity:"), key: :muzzle_velocity, type: :string},
    %{label: gettext("Powder type:"), key: :powder_type, type: :string},
    %{label: gettext("Powder grains per charge:"), key: :powder_grains_per_charge, type: :string},
    %{label: gettext("Grains:"), key: :grains, type: :string},
    %{label: gettext("Pressure:"), key: :pressure, type: :string},
    %{label: gettext("Primer type:"), key: :primer_type, type: :string},
    %{label: gettext("Firing type:"), key: :firing_type, type: :string},
    %{label: gettext("Tracer:"), key: :tracer, type: :boolean},
    %{label: gettext("Incendiary:"), key: :incendiary, type: :boolean},
    %{label: gettext("Blank:"), key: :blank, type: :boolean},
    %{label: gettext("Corrosive:"), key: :corrosive, type: :boolean},
    %{label: gettext("Manufacturer:"), key: :manufacturer, type: :string},
    %{label: gettext("UPC:"), key: :upc, type: :string}
  ]

  @impl true
  def mount(_params, _session, %{assigns: %{live_action: live_action}} = socket),
    do: {:ok, socket |> assign(show_used: false, view_table: live_action == :table)}

  @impl true
  def handle_params(%{"id" => id}, _params, %{assigns: %{live_action: live_action}} = socket) do
    socket =
      socket
      |> assign(view_table: live_action == :table)
      |> display_ammo_type(id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{ammo_type: ammo_type, current_user: current_user}} = socket
      ) do
    %{name: ammo_type_name} = ammo_type |> Ammo.delete_ammo_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: ammo_type_name)
    redirect_to = Routes.ammo_type_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_navigate(to: redirect_to)}
  end

  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> display_ammo_type()}
  end

  def handle_event(
        "toggle_table",
        _params,
        %{assigns: %{view_table: view_table, ammo_type: ammo_type}} = socket
      ) do
    new_path =
      if view_table,
        do: Routes.ammo_type_show_path(Endpoint, :show, ammo_type),
        else: Routes.ammo_type_show_path(Endpoint, :table, ammo_type)

    {:noreply, socket |> push_patch(to: new_path)}
  end

  defp display_ammo_type(
         %{assigns: %{live_action: live_action, current_user: current_user, show_used: show_used}} =
           socket,
         %AmmoType{} = ammo_type
       ) do
    fields_to_display =
      @fields_list
      |> Enum.any?(fn %{key: field, type: type} ->
        default_value =
          case type do
            :boolean -> false
            _other_type -> nil
          end

        ammo_type |> Map.get(field) != default_value
      end)

    ammo_groups = ammo_type |> Ammo.list_ammo_groups_for_type(current_user, show_used)

    [
      original_counts,
      used_packs_count,
      historical_packs_count,
      used_rounds,
      historical_round_count
    ] =
      if show_used do
        [
          ammo_groups |> Ammo.get_original_counts(current_user),
          ammo_type |> Ammo.get_used_ammo_groups_count_for_type(current_user),
          ammo_type |> Ammo.get_ammo_groups_count_for_type(current_user, true),
          ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user),
          ammo_type |> Ammo.get_historical_count_for_ammo_type(current_user)
        ]
      else
        [nil, nil, nil, nil, nil]
      end

    socket
    |> assign(
      page_title: page_title(live_action, ammo_type),
      ammo_type: ammo_type,
      ammo_groups: ammo_groups,
      cprs: ammo_groups |> Ammo.get_cprs(current_user),
      last_used_dates: ammo_groups |> ActivityLog.get_last_used_dates(current_user),
      avg_cost_per_round: ammo_type |> Ammo.get_average_cost_for_ammo_type(current_user),
      rounds: ammo_type |> Ammo.get_round_count_for_ammo_type(current_user),
      original_counts: original_counts,
      used_rounds: used_rounds,
      historical_round_count: historical_round_count,
      packs_count: ammo_type |> Ammo.get_ammo_groups_count_for_type(current_user),
      used_packs_count: used_packs_count,
      historical_packs_count: historical_packs_count,
      fields_list: @fields_list,
      fields_to_display: fields_to_display
    )
  end

  defp display_ammo_type(%{assigns: %{current_user: current_user}} = socket, ammo_type_id) do
    socket |> display_ammo_type(Ammo.get_ammo_type!(ammo_type_id, current_user))
  end

  defp display_ammo_type(%{assigns: %{ammo_type: ammo_type}} = socket) do
    socket |> display_ammo_type(ammo_type)
  end

  @spec display_currency(float()) :: String.t()
  defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)

  defp page_title(action, %{name: ammo_type_name}) when action in [:show, :table],
    do: ammo_type_name

  defp page_title(:edit, %{name: ammo_type_name}),
    do: gettext("Edit %{ammo_type_name}", ammo_type_name: ammo_type_name)
end
