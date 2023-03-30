defmodule Cannery.ActivityLogTest do
  @moduledoc """
  This module tests the ActivityLog context
  """

  use Cannery.DataCase
  import Cannery.Fixtures
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup, Ammo}

  @moduletag :activity_log_test

  describe "shot_groups" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      ammo_type = ammo_type_fixture(current_user)

      {1, [%{id: pack_id} = pack]} =
        pack_fixture(%{count: 25}, ammo_type, container, current_user)

      shot_group =
        %{count: 5, date: ~N[2022-02-13 03:17:00], notes: "some notes"}
        |> shot_group_fixture(current_user, pack)

      pack = pack_id |> Ammo.get_pack!(current_user)

      [
        current_user: current_user,
        container: container,
        ammo_type: ammo_type,
        pack: pack,
        shot_group: shot_group
      ]
    end

    test "get_shot_record_count!/1 returns the correct amount of shot records",
         %{pack: pack, current_user: current_user} do
      assert ActivityLog.get_shot_record_count!(current_user) == 1

      shot_group_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, current_user, pack)
      assert ActivityLog.get_shot_record_count!(current_user) == 2

      shot_group_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, current_user, pack)
      assert ActivityLog.get_shot_record_count!(current_user) == 3

      other_user = user_fixture()
      assert ActivityLog.get_shot_record_count!(other_user) == 0

      container = container_fixture(other_user)
      ammo_type = ammo_type_fixture(other_user)
      {1, [pack]} = pack_fixture(%{count: 25}, ammo_type, container, other_user)
      shot_group_fixture(%{count: 1, date: ~N[2022-02-13 03:17:00]}, other_user, pack)
      assert ActivityLog.get_shot_record_count!(other_user) == 1
    end

    test "get_shot_group!/2 returns the shot_group with given id",
         %{shot_group: shot_group, current_user: current_user} do
      assert ActivityLog.get_shot_group!(shot_group.id, current_user) == shot_group
    end

    test "get_shot_group!/2 does not return a shot_group of another user",
         %{shot_group: shot_group} do
      another_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_group!(shot_group.id, another_user)
      end
    end

    test "create_shot_group/3 with valid data creates a shot_group",
         %{current_user: current_user, pack: pack} do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, pack)

      assert shot_group.count == 10
      assert shot_group.date == ~D[2022-02-13]
      assert shot_group.notes == "some notes"
    end

    test "create_shot_group/3 removes corresponding count from pack",
         %{
           current_user: current_user,
           pack: %{id: pack_id, count: org_count} = pack
         } do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, pack)

      %{count: new_count} = pack_id |> Ammo.get_pack!(current_user)

      assert org_count - shot_group.count == new_count
      assert new_count == 10
    end

    test "create_shot_group/3 does not remove more tha pack amount",
         %{current_user: current_user, pack: %{id: pack_id} = pack} do
      valid_attrs = %{count: 20, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{}} = ActivityLog.create_shot_group(valid_attrs, current_user, pack)

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert pack.count == 0

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(%{count: 1}, current_user, pack)
    end

    test "create_shot_group/3 with invalid data returns error changeset",
         %{current_user: current_user, pack: pack} do
      invalid_params = %{count: nil, date: nil, notes: nil}

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(invalid_params, current_user, pack)
    end

    test "update_shot_group/3 with valid data updates the shot_group and pack",
         %{
           shot_group: shot_group,
           pack: %{id: pack_id},
           current_user: current_user
         } do
      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{
                   count: 10,
                   date: ~D[2022-02-13],
                   notes: "some updated notes"
                 },
                 current_user
               )

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert shot_group.count == 10
      assert pack.count == 15
      assert shot_group.date == ~D[2022-02-13]
      assert shot_group.notes == "some updated notes"

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{
                   count: 25,
                   date: ~D[2022-02-13],
                   notes: "some updated notes"
                 },
                 current_user
               )

      pack = pack_id |> Ammo.get_pack!(current_user)

      assert shot_group.count == 25
      assert pack.count == 0
    end

    test "update_shot_group/3 with invalid data returns error changeset",
         %{shot_group: shot_group, current_user: current_user} do
      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{count: 26, date: nil, notes: nil},
                 current_user
               )

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{count: -1, date: nil, notes: nil},
                 current_user
               )

      assert shot_group == ActivityLog.get_shot_group!(shot_group.id, current_user)
    end

    test "delete_shot_group/2 deletes the shot_group and adds value back",
         %{shot_group: shot_group, current_user: current_user, pack: %{id: pack_id}} do
      assert {:ok, %ShotGroup{}} = ActivityLog.delete_shot_group(shot_group, current_user)

      assert %{count: 25} = pack_id |> Ammo.get_pack!(current_user)

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_group!(shot_group.id, current_user)
      end
    end

    test "get_used_count/2 returns accurate used count", %{
      pack: pack,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [another_pack]} = pack_fixture(ammo_type, container, current_user)
      assert 0 = another_pack |> ActivityLog.get_used_count(current_user)
      assert 5 = pack |> ActivityLog.get_used_count(current_user)

      shot_group_fixture(%{count: 15}, current_user, pack)
      assert 20 = pack |> ActivityLog.get_used_count(current_user)

      shot_group_fixture(%{count: 10}, current_user, pack)
      assert 30 = pack |> ActivityLog.get_used_count(current_user)

      {1, [another_pack]} = pack_fixture(ammo_type, container, current_user)
      assert 0 = another_pack |> ActivityLog.get_used_count(current_user)
    end

    test "get_used_counts/2 returns accurate used counts", %{
      pack: %{id: pack_id} = pack,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(ammo_type, container, current_user)

      assert %{pack_id => 5} ==
               [pack, another_pack] |> ActivityLog.get_used_counts(current_user)

      shot_group_fixture(%{count: 5}, current_user, another_pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 5} = used_counts
      assert %{^another_pack_id => 5} = used_counts

      shot_group_fixture(%{count: 15}, current_user, pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 20} = used_counts
      assert %{^another_pack_id => 5} = used_counts

      shot_group_fixture(%{count: 10}, current_user, pack)
      used_counts = [pack, another_pack] |> ActivityLog.get_used_counts(current_user)
      assert %{^pack_id => 30} = used_counts
      assert %{^another_pack_id => 5} = used_counts
    end

    test "get_last_used_date/2 returns accurate used count", %{
      pack: pack,
      ammo_type: ammo_type,
      container: container,
      shot_group: %{date: date},
      current_user: current_user
    } do
      {1, [another_pack]} = pack_fixture(ammo_type, container, current_user)
      assert another_pack |> ActivityLog.get_last_used_date(current_user) |> is_nil()
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_group_fixture(%{date: ~D[2022-11-10]}, current_user, pack)
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_group_fixture(%{date: ~D[2022-11-11]}, current_user, pack)
      assert ^date = pack |> ActivityLog.get_last_used_date(current_user)
    end

    test "get_last_used_dates/2 returns accurate used counts", %{
      pack: %{id: pack_id} = pack,
      ammo_type: ammo_type,
      container: container,
      shot_group: %{date: date},
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(ammo_type, container, current_user)

      # unset date
      assert %{pack_id => date} ==
               [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      shot_group_fixture(%{date: ~D[2022-11-09]}, current_user, another_pack)

      # setting initial date
      last_used_shot_groups =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ^date} = last_used_shot_groups
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_groups

      # setting another date
      shot_group_fixture(%{date: ~D[2022-11-10]}, current_user, pack)

      last_used_shot_groups =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ~D[2022-11-10]} = last_used_shot_groups
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_groups

      # setting yet another date
      shot_group_fixture(%{date: ~D[2022-11-11]}, current_user, pack)

      last_used_shot_groups =
        [pack, another_pack] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^pack_id => ~D[2022-11-11]} = last_used_shot_groups
      assert %{^another_pack_id => ~D[2022-11-09]} = last_used_shot_groups
    end

    test "get_used_count_for_ammo_type/2 gets accurate used round count for ammo type",
         %{ammo_type: ammo_type, pack: pack, current_user: current_user} do
      another_ammo_type = ammo_type_fixture(current_user)
      assert 0 = another_ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)
      assert 5 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)

      shot_group_fixture(%{count: 5}, current_user, pack)
      assert 10 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)

      shot_group_fixture(%{count: 1}, current_user, pack)
      assert 11 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)
    end

    test "get_used_count_for_ammo_types/2 gets accurate used round count for ammo types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      container: container,
      current_user: current_user
    } do
      # testing unused ammo type
      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)
      {1, [pack]} = pack_fixture(another_ammo_type, container, current_user)

      assert %{ammo_type_id => 5} ==
               [ammo_type, another_ammo_type]
               |> ActivityLog.get_used_count_for_ammo_types(current_user)

      # use generated pack
      shot_group_fixture(%{count: 5}, current_user, pack)

      used_counts =
        [ammo_type, another_ammo_type] |> ActivityLog.get_used_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 5} = used_counts
      assert %{^another_ammo_type_id => 5} = used_counts

      # use generated pack again
      shot_group_fixture(%{count: 1}, current_user, pack)

      used_counts =
        [ammo_type, another_ammo_type] |> ActivityLog.get_used_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 5} = used_counts
      assert %{^another_ammo_type_id => 6} = used_counts
    end
  end

  describe "list_shot_groups/3" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      ammo_type = ammo_type_fixture(current_user)
      {1, [pack]} = pack_fixture(ammo_type, container, current_user)

      [
        current_user: current_user,
        container: container,
        ammo_type: ammo_type,
        pack: pack
      ]
    end

    test "list_shot_groups/3 returns relevant shot_groups for a type",
         %{current_user: current_user, container: container} do
      other_user = user_fixture()
      other_container = container_fixture(other_user)

      for class <- ["rifle", "shotgun", "pistol"] do
        other_ammo_type = ammo_type_fixture(%{class: class}, other_user)
        {1, [other_pack]} = pack_fixture(other_ammo_type, other_container, other_user)
        shot_group_fixture(other_user, other_pack)
      end

      rifle_ammo_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_ammo_type, container, current_user)
      rifle_shot_group = shot_group_fixture(current_user, rifle_pack)

      shotgun_ammo_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_ammo_type, container, current_user)
      shotgun_shot_group = shot_group_fixture(current_user, shotgun_pack)

      pistol_ammo_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_ammo_type, container, current_user)
      pistol_shot_group = shot_group_fixture(current_user, pistol_pack)

      assert [^rifle_shot_group] = ActivityLog.list_shot_groups(:rifle, current_user)
      assert [^shotgun_shot_group] = ActivityLog.list_shot_groups(:shotgun, current_user)
      assert [^pistol_shot_group] = ActivityLog.list_shot_groups(:pistol, current_user)

      shot_groups = ActivityLog.list_shot_groups(:all, current_user)
      assert Enum.count(shot_groups) == 3
      assert rifle_shot_group in shot_groups
      assert shotgun_shot_group in shot_groups
      assert pistol_shot_group in shot_groups

      shot_groups = ActivityLog.list_shot_groups(nil, current_user)
      assert Enum.count(shot_groups) == 3
      assert rifle_shot_group in shot_groups
      assert shotgun_shot_group in shot_groups
      assert pistol_shot_group in shot_groups
    end

    test "list_shot_groups/3 returns relevant shot_groups for a search", %{
      ammo_type: ammo_type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      shot_group_a = shot_group_fixture(%{notes: "amazing"}, current_user, pack)

      {1, [another_pack]} =
        pack_fixture(%{notes: "stupendous"}, ammo_type, container, current_user)

      shot_group_b = shot_group_fixture(current_user, another_pack)

      another_ammo_type = ammo_type_fixture(%{name: "fabulous ammo"}, current_user)

      {1, [yet_another_pack]} = pack_fixture(another_ammo_type, container, current_user)

      shot_group_c = shot_group_fixture(current_user, yet_another_pack)

      another_user = user_fixture()
      another_container = container_fixture(another_user)
      another_ammo_type = ammo_type_fixture(another_user)

      {1, [another_pack]} = pack_fixture(another_ammo_type, another_container, another_user)

      _shouldnt_return = shot_group_fixture(another_user, another_pack)

      # notes
      assert ActivityLog.list_shot_groups("amazing", :all, current_user) == [shot_group_a]

      # pack attributes
      assert ActivityLog.list_shot_groups("stupendous", :all, current_user) == [shot_group_b]

      # ammo type attributes
      assert ActivityLog.list_shot_groups("fabulous", :all, current_user) == [shot_group_c]
    end
  end
end
