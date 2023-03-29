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

      {1, [%{id: ammo_group_id} = ammo_group]} =
        ammo_group_fixture(%{count: 25}, ammo_type, container, current_user)

      shot_group =
        %{count: 5, date: ~N[2022-02-13 03:17:00], notes: "some notes"}
        |> shot_group_fixture(current_user, ammo_group)

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      [
        current_user: current_user,
        container: container,
        ammo_type: ammo_type,
        ammo_group: ammo_group,
        shot_group: shot_group
      ]
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
         %{current_user: current_user, ammo_group: ammo_group} do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      assert shot_group.count == 10
      assert shot_group.date == ~D[2022-02-13]
      assert shot_group.notes == "some notes"
    end

    test "create_shot_group/3 removes corresponding count from ammo group",
         %{
           current_user: current_user,
           ammo_group: %{id: ammo_group_id, count: org_count} = ammo_group
         } do
      valid_attrs = %{count: 10, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      %{count: new_count} = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert org_count - shot_group.count == new_count
      assert new_count == 10
    end

    test "create_shot_group/3 does not remove more than ammo group amount",
         %{current_user: current_user, ammo_group: %{id: ammo_group_id} = ammo_group} do
      valid_attrs = %{count: 20, date: ~D[2022-02-13], notes: "some notes"}

      assert {:ok, %ShotGroup{}} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert ammo_group.count == 0

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(%{count: 1}, current_user, ammo_group)
    end

    test "create_shot_group/3 with invalid data returns error changeset",
         %{current_user: current_user, ammo_group: ammo_group} do
      invalid_params = %{count: nil, date: nil, notes: nil}

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(invalid_params, current_user, ammo_group)
    end

    test "update_shot_group/3 with valid data updates the shot_group and ammo_group",
         %{
           shot_group: shot_group,
           ammo_group: %{id: ammo_group_id},
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

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert shot_group.count == 10
      assert ammo_group.count == 15
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

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert shot_group.count == 25
      assert ammo_group.count == 0
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
         %{shot_group: shot_group, current_user: current_user, ammo_group: %{id: ammo_group_id}} do
      assert {:ok, %ShotGroup{}} = ActivityLog.delete_shot_group(shot_group, current_user)

      assert %{count: 25} = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_group!(shot_group.id, current_user)
      end
    end

    test "get_used_count/2 returns accurate used count", %{
      ammo_group: ammo_group,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [another_ammo_group]} = ammo_group_fixture(ammo_type, container, current_user)
      assert 0 = another_ammo_group |> ActivityLog.get_used_count(current_user)
      assert 5 = ammo_group |> ActivityLog.get_used_count(current_user)

      shot_group_fixture(%{count: 15}, current_user, ammo_group)
      assert 20 = ammo_group |> ActivityLog.get_used_count(current_user)

      shot_group_fixture(%{count: 10}, current_user, ammo_group)
      assert 30 = ammo_group |> ActivityLog.get_used_count(current_user)

      {1, [another_ammo_group]} = ammo_group_fixture(ammo_type, container, current_user)
      assert 0 = another_ammo_group |> ActivityLog.get_used_count(current_user)
    end

    test "get_used_counts/2 returns accurate used counts", %{
      ammo_group: %{id: ammo_group_id} = ammo_group,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(ammo_type, container, current_user)

      assert %{ammo_group_id => 5} ==
               [ammo_group, another_ammo_group] |> ActivityLog.get_used_counts(current_user)

      shot_group_fixture(%{count: 5}, current_user, another_ammo_group)
      used_counts = [ammo_group, another_ammo_group] |> ActivityLog.get_used_counts(current_user)
      assert %{^ammo_group_id => 5} = used_counts
      assert %{^another_ammo_group_id => 5} = used_counts

      shot_group_fixture(%{count: 15}, current_user, ammo_group)
      used_counts = [ammo_group, another_ammo_group] |> ActivityLog.get_used_counts(current_user)
      assert %{^ammo_group_id => 20} = used_counts
      assert %{^another_ammo_group_id => 5} = used_counts

      shot_group_fixture(%{count: 10}, current_user, ammo_group)
      used_counts = [ammo_group, another_ammo_group] |> ActivityLog.get_used_counts(current_user)
      assert %{^ammo_group_id => 30} = used_counts
      assert %{^another_ammo_group_id => 5} = used_counts
    end

    test "get_last_used_date/2 returns accurate used count", %{
      ammo_group: ammo_group,
      ammo_type: ammo_type,
      container: container,
      shot_group: %{date: date},
      current_user: current_user
    } do
      {1, [another_ammo_group]} = ammo_group_fixture(ammo_type, container, current_user)
      assert another_ammo_group |> ActivityLog.get_last_used_date(current_user) |> is_nil()
      assert ^date = ammo_group |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_group_fixture(%{date: ~D[2022-11-10]}, current_user, ammo_group)
      assert ^date = ammo_group |> ActivityLog.get_last_used_date(current_user)

      %{date: date} = shot_group_fixture(%{date: ~D[2022-11-11]}, current_user, ammo_group)
      assert ^date = ammo_group |> ActivityLog.get_last_used_date(current_user)
    end

    test "get_last_used_dates/2 returns accurate used counts", %{
      ammo_group: %{id: ammo_group_id} = ammo_group,
      ammo_type: ammo_type,
      container: container,
      shot_group: %{date: date},
      current_user: current_user
    } do
      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(ammo_type, container, current_user)

      # unset date
      assert %{ammo_group_id => date} ==
               [ammo_group, another_ammo_group] |> ActivityLog.get_last_used_dates(current_user)

      shot_group_fixture(%{date: ~D[2022-11-09]}, current_user, another_ammo_group)

      # setting initial date
      last_used_shot_groups =
        [ammo_group, another_ammo_group] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^ammo_group_id => ^date} = last_used_shot_groups
      assert %{^another_ammo_group_id => ~D[2022-11-09]} = last_used_shot_groups

      # setting another date
      shot_group_fixture(%{date: ~D[2022-11-10]}, current_user, ammo_group)

      last_used_shot_groups =
        [ammo_group, another_ammo_group] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^ammo_group_id => ~D[2022-11-10]} = last_used_shot_groups
      assert %{^another_ammo_group_id => ~D[2022-11-09]} = last_used_shot_groups

      # setting yet another date
      shot_group_fixture(%{date: ~D[2022-11-11]}, current_user, ammo_group)

      last_used_shot_groups =
        [ammo_group, another_ammo_group] |> ActivityLog.get_last_used_dates(current_user)

      assert %{^ammo_group_id => ~D[2022-11-11]} = last_used_shot_groups
      assert %{^another_ammo_group_id => ~D[2022-11-09]} = last_used_shot_groups
    end

    test "get_used_count_for_ammo_type/2 gets accurate used round count for ammo type",
         %{ammo_type: ammo_type, ammo_group: ammo_group, current_user: current_user} do
      another_ammo_type = ammo_type_fixture(current_user)
      assert 0 = another_ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)
      assert 5 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)

      shot_group_fixture(%{count: 5}, current_user, ammo_group)
      assert 10 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)

      shot_group_fixture(%{count: 1}, current_user, ammo_group)
      assert 11 = ammo_type |> ActivityLog.get_used_count_for_ammo_type(current_user)
    end

    test "get_used_count_for_ammo_types/2 gets accurate used round count for ammo types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      container: container,
      current_user: current_user
    } do
      # testing unused ammo type
      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)
      {1, [ammo_group]} = ammo_group_fixture(another_ammo_type, container, current_user)

      assert %{ammo_type_id => 5} ==
               [ammo_type, another_ammo_type]
               |> ActivityLog.get_used_count_for_ammo_types(current_user)

      # use generated ammo group
      shot_group_fixture(%{count: 5}, current_user, ammo_group)

      used_counts =
        [ammo_type, another_ammo_type] |> ActivityLog.get_used_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 5} = used_counts
      assert %{^another_ammo_type_id => 5} = used_counts

      # use generated ammo group again
      shot_group_fixture(%{count: 1}, current_user, ammo_group)

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
      {1, [ammo_group]} = ammo_group_fixture(ammo_type, container, current_user)

      [
        current_user: current_user,
        container: container,
        ammo_type: ammo_type,
        ammo_group: ammo_group
      ]
    end

    test "list_shot_groups/3 returns relevant shot_groups for a type",
         %{current_user: current_user, container: container} do
      other_user = user_fixture()
      other_container = container_fixture(other_user)

      for type <- ["rifle", "shotgun", "pistol"] do
        other_ammo_type = ammo_type_fixture(%{type: type}, other_user)
        {1, [other_ammo_group]} = ammo_group_fixture(other_ammo_type, other_container, other_user)
        shot_group_fixture(other_user, other_ammo_group)
      end

      rifle_ammo_type = ammo_type_fixture(%{type: "rifle"}, current_user)
      {1, [rifle_ammo_group]} = ammo_group_fixture(rifle_ammo_type, container, current_user)
      rifle_shot_group = shot_group_fixture(current_user, rifle_ammo_group)

      shotgun_ammo_type = ammo_type_fixture(%{type: "shotgun"}, current_user)
      {1, [shotgun_ammo_group]} = ammo_group_fixture(shotgun_ammo_type, container, current_user)
      shotgun_shot_group = shot_group_fixture(current_user, shotgun_ammo_group)

      pistol_ammo_type = ammo_type_fixture(%{type: "pistol"}, current_user)
      {1, [pistol_ammo_group]} = ammo_group_fixture(pistol_ammo_type, container, current_user)
      pistol_shot_group = shot_group_fixture(current_user, pistol_ammo_group)

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
      ammo_group: ammo_group,
      container: container,
      current_user: current_user
    } do
      shot_group_a = shot_group_fixture(%{notes: "amazing"}, current_user, ammo_group)

      {1, [another_ammo_group]} =
        ammo_group_fixture(%{notes: "stupendous"}, ammo_type, container, current_user)

      shot_group_b = shot_group_fixture(current_user, another_ammo_group)

      another_ammo_type = ammo_type_fixture(%{name: "fabulous ammo"}, current_user)

      {1, [yet_another_ammo_group]} =
        ammo_group_fixture(another_ammo_type, container, current_user)

      shot_group_c = shot_group_fixture(current_user, yet_another_ammo_group)

      another_user = user_fixture()
      another_container = container_fixture(another_user)
      another_ammo_type = ammo_type_fixture(another_user)

      {1, [another_ammo_group]} =
        ammo_group_fixture(another_ammo_type, another_container, another_user)

      _shouldnt_return = shot_group_fixture(another_user, another_ammo_group)

      # notes
      assert ActivityLog.list_shot_groups("amazing", :all, current_user) == [shot_group_a]

      # ammo group attributes
      assert ActivityLog.list_shot_groups("stupendous", :all, current_user) == [shot_group_b]

      # ammo type attributes
      assert ActivityLog.list_shot_groups("fabulous", :all, current_user) == [shot_group_c]
    end
  end
end
