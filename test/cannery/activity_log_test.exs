defmodule Cannery.ActivityLogTest do
  @moduledoc """
  This module tests the ActivityLog context
  """

  use Cannery.DataCase
  import Cannery.Fixtures

  alias Cannery.{
    ActivityLog,
    ActivityLog.ShotGroup,
    Ammo
  }

  @moduletag :activity_log_test

  describe "shot_groups" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      ammo_type = ammo_type_fixture(current_user)

      %{id: ammo_group_id} =
        ammo_group = ammo_group_fixture(%{"count" => 25}, ammo_type, container, current_user)

      shot_group =
        %{"count" => 5, "date" => ~N[2022-02-13 03:17:00], "notes" => "some notes"}
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

    test "list_shot_groups/0 returns all shot_groups",
         %{shot_group: shot_group, current_user: current_user} do
      assert ActivityLog.list_shot_groups(current_user) == [shot_group]
    end

    test "get_shot_group!/1 returns the shot_group with given id",
         %{shot_group: shot_group, current_user: current_user} do
      assert ActivityLog.get_shot_group!(shot_group.id, current_user) == shot_group
    end

    test "get_shot_group!/1 does not return a shot_group of another user",
         %{shot_group: shot_group} do
      another_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_group!(shot_group.id, another_user)
      end
    end

    test "create_shot_group/1 with valid data creates a shot_group",
         %{current_user: current_user, ammo_group: ammo_group} do
      valid_attrs = %{"count" => 10, "date" => ~D[2022-02-13], "notes" => "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      assert shot_group.count == 10
      assert shot_group.date == ~D[2022-02-13]
      assert shot_group.notes == "some notes"
    end

    test "create_shot_group/1 removes corresponding count from ammo group",
         %{
           current_user: current_user,
           ammo_group: %{id: ammo_group_id, count: org_count} = ammo_group
         } do
      valid_attrs = %{"count" => 10, "date" => ~D[2022-02-13], "notes" => "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      %{count: new_count} = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert org_count - shot_group.count == new_count
      assert new_count == 10
    end

    test "create_shot_group/1 does not remove more than ammo group amount",
         %{current_user: current_user, ammo_group: %{id: ammo_group_id} = ammo_group} do
      valid_attrs = %{"count" => 20, "date" => ~D[2022-02-13], "notes" => "some notes"}

      assert {:ok, %ShotGroup{}} =
               ActivityLog.create_shot_group(valid_attrs, current_user, ammo_group)

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert ammo_group.count == 0

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(%{"count" => 1}, current_user, ammo_group)
    end

    test "create_shot_group/1 with invalid data returns error changeset",
         %{current_user: current_user, ammo_group: ammo_group} do
      invalid_params = %{"count" => nil, "date" => nil, "notes" => nil}

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.create_shot_group(invalid_params, current_user, ammo_group)
    end

    test "update_shot_group/2 with valid data updates the shot_group and ammo_group",
         %{
           shot_group: shot_group,
           ammo_group: %{id: ammo_group_id},
           current_user: current_user
         } do
      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{
                   "count" => 10,
                   "date" => ~D[2022-02-13],
                   "notes" => "some updated notes"
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
                   "count" => 25,
                   "date" => ~D[2022-02-13],
                   "notes" => "some updated notes"
                 },
                 current_user
               )

      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert shot_group.count == 25
      assert ammo_group.count == 0
    end

    test "update_shot_group/2 with invalid data returns error changeset",
         %{shot_group: shot_group, current_user: current_user} do
      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{"count" => 26, "date" => nil, "notes" => nil},
                 current_user
               )

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_group(
                 shot_group,
                 %{"count" => -1, "date" => nil, "notes" => nil},
                 current_user
               )

      assert shot_group == ActivityLog.get_shot_group!(shot_group.id, current_user)
    end

    test "delete_shot_group/1 deletes the shot_group and adds value back",
         %{shot_group: shot_group, current_user: current_user, ammo_group: %{id: ammo_group_id}} do
      assert {:ok, %ShotGroup{}} = ActivityLog.delete_shot_group(shot_group, current_user)

      assert %{count: 25} = ammo_group_id |> Ammo.get_ammo_group!(current_user)

      assert_raise Ecto.NoResultsError, fn ->
        ActivityLog.get_shot_group!(shot_group.id, current_user)
      end
    end

    test "change_shot_group/1 returns a shot_group changeset",
         %{shot_group: shot_group} do
      assert %Ecto.Changeset{} = ActivityLog.change_shot_group(shot_group)
    end
  end
end
