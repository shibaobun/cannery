defmodule CanneryWeb.ExportController do
  use CanneryWeb, :controller
  alias Cannery.{ActivityLog, Ammo, Containers}

  def export(%{assigns: %{current_user: current_user}} = conn, %{"mode" => "json"}) do
    ammo_types =
      Ammo.list_ammo_types(current_user)
      |> Enum.map(fn ammo_type ->
        average_cost = ammo_type |> Ammo.get_average_cost_for_ammo_type!(current_user)
        round_count = ammo_type |> Ammo.get_round_count_for_ammo_type(current_user)
        used_count = ammo_type |> Ammo.get_used_count_for_ammo_type(current_user)
        ammo_group_count = ammo_type |> Ammo.get_ammo_groups_count_for_type(current_user, true)

        ammo_type
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "average_cost" => average_cost,
          "round_count" => round_count,
          "used_count" => used_count,
          "ammo_group_count" => ammo_group_count
        })
      end)

    ammo_groups =
      Ammo.list_ammo_groups(current_user, true)
      |> Enum.map(fn ammo_group ->
        used_count = ammo_group |> Ammo.get_used_count()
        percentage_remaining = ammo_group |> Ammo.get_percentage_remaining()

        ammo_group
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "used_count" => used_count,
          "percentage_remaining" => percentage_remaining
        })
      end)

    shot_groups = ActivityLog.list_shot_groups(current_user)

    containers =
      Containers.list_containers(current_user)
      |> Enum.map(fn container ->
        ammo_group_count = container |> Containers.get_container_ammo_group_count!()
        round_count = container |> Containers.get_container_rounds!()

        container
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.merge(%{
          "ammo_group_count" => ammo_group_count,
          "round_count" => round_count
        })
      end)

    json(conn, %{
      user: current_user,
      ammo_types: ammo_types,
      ammo_groups: ammo_groups,
      shot_groups: shot_groups,
      containers: containers
    })
  end
end
