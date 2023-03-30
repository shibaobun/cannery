defmodule CanneryWeb.ExportController do
  use CanneryWeb, :controller
  alias Cannery.{ActivityLog, Ammo, Containers}

  def export(%{assigns: %{current_user: current_user}} = conn, %{"mode" => "json"}) do
    ammo_types = Ammo.list_ammo_types(current_user, :all)
    used_counts = ammo_types |> ActivityLog.get_used_count_for_ammo_types(current_user)
    round_counts = ammo_types |> Ammo.get_round_count_for_ammo_types(current_user)
    pack_counts = ammo_types |> Ammo.get_packs_count_for_types(current_user)

    total_pack_counts = ammo_types |> Ammo.get_packs_count_for_types(current_user, true)

    average_costs = ammo_types |> Ammo.get_average_cost_for_ammo_types(current_user)

    ammo_types =
      ammo_types
      |> Enum.map(fn %{id: ammo_type_id} = ammo_type ->
        ammo_type
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "average_cost" => Map.get(average_costs, ammo_type_id),
          "round_count" => Map.get(round_counts, ammo_type_id, 0),
          "used_count" => Map.get(used_counts, ammo_type_id, 0),
          "pack_count" => Map.get(pack_counts, ammo_type_id, 0),
          "total_pack_count" => Map.get(total_pack_counts, ammo_type_id, 0)
        })
      end)

    packs = Ammo.list_packs(nil, :all, current_user, true)
    used_counts = packs |> ActivityLog.get_used_counts(current_user)
    original_counts = packs |> Ammo.get_original_counts(current_user)
    cprs = packs |> Ammo.get_cprs(current_user)
    percentages_remaining = packs |> Ammo.get_percentages_remaining(current_user)

    packs =
      packs
      |> Enum.map(fn %{id: pack_id} = pack ->
        pack
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "used_count" => Map.get(used_counts, pack_id),
          "percentage_remaining" => Map.fetch!(percentages_remaining, pack_id),
          "original_count" => Map.get(original_counts, pack_id),
          "cpr" => Map.get(cprs, pack_id)
        })
      end)

    shot_groups = ActivityLog.list_shot_groups(:all, current_user)

    containers =
      Containers.list_containers(current_user)
      |> Enum.map(fn container ->
        pack_count = container |> Ammo.get_packs_count_for_container!(current_user)
        round_count = container |> Ammo.get_round_count_for_container!(current_user)

        container
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "pack_count" => pack_count,
          "round_count" => round_count
        })
      end)

    json(conn, %{
      user: current_user,
      ammo_types: ammo_types,
      packs: packs,
      shot_groups: shot_groups,
      containers: containers
    })
  end
end
