defmodule CanneryWeb.ExportControllerTest do
  @moduledoc """
  Tests the export function
  """

  use CanneryWeb.ConnCase
  alias Cannery.{ActivityLog, Ammo, Containers, Repo}

  @moduletag :export_controller_test

  setup [:register_and_log_in_user]

  defp add_data(%{current_user: current_user}) do
    ammo_type = ammo_type_fixture(current_user)
    container = container_fixture(current_user)
    tag = tag_fixture(current_user)
    Containers.add_tag!(container, tag, current_user)
    {1, [pack]} = pack_fixture(ammo_type, container, current_user)
    shot_record = shot_record_fixture(current_user, pack)
    pack = pack |> Repo.reload!()

    %{
      ammo_type: ammo_type,
      pack: pack,
      container: container,
      shot_record: shot_record,
      tag: tag
    }
  end

  describe "Exports data" do
    setup [:add_data]

    test "in JSON", %{
      conn: conn,
      current_user: current_user,
      container: container,
      ammo_type: ammo_type,
      pack: pack,
      shot_record: shot_record,
      tag: tag
    } do
      conn = get(conn, Routes.export_path(conn, :export, :json))

      ideal_pack = %{
        "ammo_type_id" => pack.ammo_type_id,
        "container_id" => pack.container_id,
        "count" => pack.count,
        "id" => pack.id,
        "notes" => pack.notes,
        "price_paid" => pack.price_paid,
        "staged" => pack.staged,
        "used_count" => pack |> ActivityLog.get_used_count(current_user),
        "original_count" => pack |> Ammo.get_original_count(current_user),
        "cpr" => pack |> Ammo.get_cpr(current_user),
        "percentage_remaining" => pack |> Ammo.get_percentage_remaining(current_user)
      }

      ideal_ammo_type = %{
        "blank" => ammo_type.blank,
        "bullet_core" => ammo_type.bullet_core,
        "bullet_type" => ammo_type.bullet_type,
        "caliber" => ammo_type.caliber,
        "cartridge" => ammo_type.cartridge,
        "case_material" => ammo_type.case_material,
        "corrosive" => ammo_type.corrosive,
        "desc" => ammo_type.desc,
        "firing_type" => ammo_type.firing_type,
        "grains" => ammo_type.grains,
        "id" => ammo_type.id,
        "incendiary" => ammo_type.incendiary,
        "jacket_type" => ammo_type.jacket_type,
        "manufacturer" => ammo_type.manufacturer,
        "muzzle_velocity" => ammo_type.muzzle_velocity,
        "name" => ammo_type.name,
        "powder_grains_per_charge" => ammo_type.powder_grains_per_charge,
        "powder_type" => ammo_type.powder_type,
        "pressure" => ammo_type.pressure,
        "primer_type" => ammo_type.primer_type,
        "tracer" => ammo_type.tracer,
        "upc" => ammo_type.upc,
        "average_cost" => ammo_type |> Ammo.get_average_cost_for_ammo_type(current_user),
        "round_count" => ammo_type |> Ammo.get_round_count_for_ammo_type(current_user),
        "used_count" => ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user),
        "pack_count" => ammo_type |> Ammo.get_packs_count_for_type(current_user),
        "total_pack_count" => ammo_type |> Ammo.get_packs_count_for_type(current_user, true)
      }

      ideal_container = %{
        "desc" => container.desc,
        "id" => container.id,
        "location" => container.location,
        "name" => container.name,
        "tags" => [
          %{
            "id" => tag.id,
            "name" => tag.name,
            "bg_color" => tag.bg_color,
            "text_color" => tag.text_color
          }
        ],
        "type" => container.type,
        "pack_count" => container |> Ammo.get_packs_count_for_container!(current_user),
        "round_count" => container |> Ammo.get_round_count_for_container!(current_user)
      }

      ideal_shot_record = %{
        "pack_id" => shot_record.pack_id,
        "count" => shot_record.count,
        "date" => to_string(shot_record.date),
        "id" => shot_record.id,
        "notes" => shot_record.notes
      }

      ideal_user = %{
        "confirmed_at" =>
          current_user.confirmed_at |> Jason.encode!() |> String.replace(~r/\"/, ""),
        "email" => current_user.email,
        "id" => current_user.id,
        "locale" => current_user.locale,
        "role" => to_string(current_user.role),
        "inserted_at" => current_user.inserted_at |> NaiveDateTime.to_iso8601(),
        "updated_at" => current_user.updated_at |> NaiveDateTime.to_iso8601()
      }

      json_resp = conn |> json_response(200)
      assert %{"packs" => [^ideal_pack]} = json_resp
      assert %{"ammo_types" => [^ideal_ammo_type]} = json_resp
      assert %{"containers" => [^ideal_container]} = json_resp
      assert %{"shot_records" => [^ideal_shot_record]} = json_resp
      assert %{"user" => ^ideal_user} = json_resp
    end
  end
end
