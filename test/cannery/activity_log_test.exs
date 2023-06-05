defmodule Cannery.ActivityLogTest do
  @moduledoc """
  This module tests the ActivityLog context
  """

  use Cannery.DataCase, async: true
  import Cannery.Fixtures
  alias Cannery.{ActivityLog, ActivityLog.ShotRecord, Ammo}

  @moduletag :activity_log_test

  describe "shot_records" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      type = type_fixture(current_user)

      {1, [%{id: pack_id} = pack]} = pack_fixture(%{count: 25}, type, container, current_user)

      shot_record =
        %{count: 5, date: ~N[2022-02-13 03:17:00], notes: "some notes"}
        |> shot_record_fixture(current_user, pack)

      pack = pack_id |> Ammo.get_pack!(current_user)

      [
        current_user: current_user,
        container: container,
        type: type,
        pack: pack,
        shot_record: shot_record
      ]
    end

    test "get_shot_record_count!/1 returns the correct amount of shot records",
         %{pack: pack, current_user: current_user} do
      assert ActivityLog.get_shot_record_count!(current_user) == 1

      shot_record_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, current_user, pack)
      assert ActivityLog.get_shot_record_count!(current_user) == 2

      shot_record_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, current_user, pack)
      assert ActivityLog.get_shot_record_count!(current_user) == 3

      other_user = user_fixture()
      assert ActivityLog.get_shot_record_count!(other_user) == 0

      container = container_fixture(other_user)
      type = type_fixture(other_user)
      {1, [pack]} = pack_fixture(%{count: 25}, type, container, other_user)
      shot_record_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, other_user, pack)
      assert ActivityLog.get_shot_record_count!(other_user) == 1
    end

    test "get_shot_record!/2 returns the shot_record with given id",
         %{shot_record: shot_record, current_user: current_user} do
      assert ActivityLog.get_shot_record!(shot_record.id, current_user) == shot_record
    end

    test "get_shot_record!/2 does not return a shot_record of another user",
         %{shot_record: shot_record} do
      another_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_record!(shot_record.id, another_user)
      end
    end

    test "create_shot_record/3 with valid data creates a shot_record",
         %{current_user: current_user, pack: pack} do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotRecord{} = shot_record} =
               ActivityLog.create_shot_record(valid_attrs, current_user, pack)

      assert shot_record.count == 10
      assert shot_record.date == ~D[2022-02-13]
      assert shot_record.notes == "some notes"
    end

    test "create_shot_record/3 removes corresponding count from pack",
         %{
           current_user: current_user,
           pack: %{id: pack_id, count: org_count} = pack
         } do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotRecord{} = shot_record} =
               ActivityLog.create_shot_record(valid_attrs, current_user, pack)

      %{count: new_count} = pack_id |> Ammo.get_pack!(current_user)

      assert org_count - shot_record.count == new_count
      assert new_count == 10
    end

    test "create_shot_record/3 does not remove more tha pack amount",
         %{current_user: current_user, pack: %{id: pack_id} = pack} do
      valid_attrs = %{count: 20, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotRecord{}} =
               ActivityLog.create_shot_record(valid_attrs, current_user, pack)

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert pack.count == 0

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_record(%{count: 1}, current_user, pack)
    end

    test "create_shot_record/3 with invalid data returns error changeset",
         %{current_user: current_user, pack: pack} do
      invalid_params = %{count: nil, date: nil, notes: nil}

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_record(invalid_params, current_user, pack)
    end

    test "update_shot_record/3 with valid data updates the shot_record and pack",
         %{
           shot_record: shot_record,
           pack: %{id: pack_id},
           current_user: current_user
         } do
      assert {:ok, %ShotRecord{} = shot_record} =
               ActivityLog.update_shot_record(
                 shot_record,
                 %{
                   count: 10,
                   date: ~D[2022-02-13],
                   notes: "some updated notes"
                 },
                 current_user
               )

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert shot_record.count == 10
      assert pack.count == 15
      assert shot_record.date == ~D[2022-02-13]
      assert shot_record.notes == "some updated notes"

      assert {:ok, %ShotRecord{} = shot_record} =
               ActivityLog.update_shot_record(
                 shot_record,
                 %{
                   count: 25,
                   date: ~D[2022-02-13],
                   notes: "some updated notes"
                 },
                 current_user
               )

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert shot_record.count == 25
      assert pack.count == 0
    end

    test "update_shot_record/3 with invalid data returns error changeset",
         %{shot_record: shot_record, current_user: current_user} do
      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_record(
                 shot_record,
                 %{count: 26, date: nil, notes: nil},
                 current_user
               )

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_record(
                 shot_record,
                 %{count: -1, date: nil, notes: nil},
                 current_user
               )

      assert shot_record == ActivityLog.get_shot_record!(shot_record.id, current_user)
    end

    test "delete_shot_record/2 deletes the shot_record and adds value back",
         %{shot_record: shot_record, current_user: current_user, pack: %{id: pack_id}} do
      assert {:ok, %ShotRecord{}} = ActivityLog.delete_shot_record(shot_record, current_user)

      assert %{count: 25} = pack_id |> Ammo.get_pack!(current_user)

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_record!(shot_record.id, current_user)
      end
    end

    test "get_used_count/2 returns accurate used count for pack_id", %{
      pack: pack,
      type: type,
      container: container,
      current_user: current_user
    } do
      {1, [another_pack]} = pack_fixture(type, container, current_user)
      assert 0 = ActivityLog.get_used_count(current_user, pack_id: another_pack.id)
      assert 5 = ActivityLog.get_used_count(current_user, pack_id: pack.id)

      shot_record_fixture(%{count: 15}, current_user, pack)
      assert 20 = ActivityLog.get_used_count(current_user, pack_id: pack.id)

      shot_record_fixture(%{count: 10}, current_user, pack)
      assert 30 = ActivityLog.get_used_count(current_user, pack_id: pack.id)

      {1, [another_pack]} = pack_fixture(type, container, current_user)
      assert 0 = ActivityLog.get_used_count(current_user, pack_id: another_pack.id)
    end

    test "get_used_counts/2 returns accurate used counts", %{
      pack: %{id: pack_id} = pack,
      type: type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} = pack_fixture(type, container, current_user)

      assert %{pack_id => 5} ==
               [pack, another_pack] |> ActivityLog.get_used_counts(current_user)

      shot_record_fixture(%{count: 5}, current_user, another_pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 5} = used_counts
      assert %{^another_pack_id => 5} = used_counts

      shot_record_fixture(%{count: 15}, current_user, pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 20} = used_counts
      assert %{^another_pack_id => 5} = used_counts

      shot_record_fixture(%{count: 10}, current_user, pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 30} = used_counts
      assert %{^another_pack_id => 5} = used_counts
    end

    test "get_last_used_date/2 returns accurate used count", %{
      pack: pack,
      type: type,
      container: container,
      shot_record: %{date: date},
      current_user: current_user
    } do
      {1, [another_pack]} = pack_fixture(type, container, current_user)
      assert another_pack |> ActivityLog.get_last_used_date(current_user) |> is_nil()
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_record_fixture(%{date: ~D[2022-11-10]}, current_user, pack)
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_record_fixture(%{date: ~D[2022-11-11]}, current_user, pack)
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)
    end

    test "get_last_used_dates/2 returns accurate used counts", %{
      pack: %{id: pack_id} = pack,
      type: type,
      container: container,
      shot_record: %{date: date},
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} = pack_fixture(type, container, current_user)

      # unset date
      assert %{pack_id => date} ==
               [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      shot_record_fixture(%{date: ~D[2022-11-09]}, current_user, another_pack)

      # setting initial date
      last_used_shot_records =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ^date} = last_used_shot_records
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_records

      # setting another date
      shot_record_fixture(%{date: ~D[2022-11-10]}, current_user, pack)

      last_used_shot_records =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ~D[2022-11-10]} = last_used_shot_records
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_records

      # setting yet another date
      shot_record_fixture(%{date: ~D[2022-11-11]}, current_user, pack)

      last_used_shot_records =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ~D[2022-11-11]} = last_used_shot_records
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_records
    end

    test "get_used_count/2 gets accurate used round count for type_id",
         %{type: type, pack: pack, current_user: current_user} do
      another_type = type_fixture(current_user)
      assert 0 = ActivityLog.get_used_count(current_user, type_id: another_type.id)
      assert 5 = ActivityLog.get_used_count(current_user, type_id: type.id)

      shot_record_fixture(%{count: 5}, current_user, pack)
      assert 10 = ActivityLog.get_used_count(current_user, type_id: type.id)

      shot_record_fixture(%{count: 1}, current_user, pack)
      assert 11 = ActivityLog.get_used_count(current_user, type_id: type.id)
    end

    test "get_used_count_for_types/2 gets accurate used round count for types", %{
      type: %{id: type_id} = type,
      container: container,
      current_user: current_user
    } do
      # testing unused type
      %{id: another_type_id} = another_type = type_fixture(current_user)
      {1, [pack]} = pack_fixture(another_type, container, current_user)

      assert %{type_id => 5} ==
               [type, another_type]
               |> ActivityLog.get_used_count_for_types(current_user)

      # use generated pack
      shot_record_fixture(%{count: 5}, current_user, pack)

      used_counts = [type, another_type] |> ActivityLog.get_used_count_for_types(current_user)

      assert %{^type_id => 5} = used_counts
      assert %{^another_type_id => 5} = used_counts

      # use generated pack again
      shot_record_fixture(%{count: 1}, current_user, pack)

      used_counts = [type, another_type] |> ActivityLog.get_used_count_for_types(current_user)

      assert %{^type_id => 5} = used_counts
      assert %{^another_type_id => 6} = used_counts
    end
  end

  describe "list_shot_records/3" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      type = type_fixture(current_user)
      {1, [pack]} = pack_fixture(type, container, current_user)

      [
        current_user: current_user,
        container: container,
        type: type,
        pack: pack
      ]
    end

    test "list_shot_records/3 returns relevant shot_records for a type",
         %{current_user: current_user, container: container} do
      other_user = user_fixture()
      other_container = container_fixture(other_user)

      for class <- ["rifle", "shotgun", "pistol"] do
        other_type = type_fixture(%{class: class}, other_user)
        {1, [other_pack]} = pack_fixture(other_type, other_container, other_user)
        shot_record_fixture(other_user, other_pack)
      end

      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      rifle_shot_record = shot_record_fixture(current_user, rifle_pack)

      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      shotgun_shot_record = shot_record_fixture(current_user, shotgun_pack)

      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)
      pistol_shot_record = shot_record_fixture(current_user, pistol_pack)

      assert [^rifle_shot_record] = ActivityLog.list_shot_records(:rifle, current_user)
      assert [^shotgun_shot_record] = ActivityLog.list_shot_records(:shotgun, current_user)
      assert [^pistol_shot_record] = ActivityLog.list_shot_records(:pistol, current_user)

      shot_records = ActivityLog.list_shot_records(:all, current_user)
      assert Enum.count(shot_records) == 3
      assert rifle_shot_record in shot_records
      assert shotgun_shot_record in shot_records
      assert pistol_shot_record in shot_records

      shot_records = ActivityLog.list_shot_records(nil, current_user)
      assert Enum.count(shot_records) == 3
      assert rifle_shot_record in shot_records
      assert shotgun_shot_record in shot_records
      assert pistol_shot_record in shot_records
    end

    test "list_shot_records/3 returns relevant shot_records for a search", %{
      type: type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      shot_record_a = shot_record_fixture(%{notes: "amazing"}, current_user, pack)

      {1, [another_pack]} = pack_fixture(%{notes: "stupendous"}, type, container, current_user)

      shot_record_b = shot_record_fixture(current_user, another_pack)

      another_type = type_fixture(%{name: "fabulous ammo"}, current_user)

      {1, [yet_another_pack]} = pack_fixture(another_type, container, current_user)

      shot_record_c = shot_record_fixture(current_user, yet_another_pack)

      another_user = user_fixture()
      another_container = container_fixture(another_user)
      another_type = type_fixture(another_user)

      {1, [another_pack]} = pack_fixture(another_type, another_container, another_user)

      _shouldnt_return = shot_record_fixture(another_user, another_pack)

      # notes
      assert ActivityLog.list_shot_records("amazing", :all, current_user) == [shot_record_a]

      # pack attributes
      assert ActivityLog.list_shot_records("stupendous", :all, current_user) == [shot_record_b]

      # type attributes
      assert ActivityLog.list_shot_records("fabulous", :all, current_user) == [shot_record_c]
    end
  end
end
