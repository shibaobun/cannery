defmodule Cannery.ActivityLogTest do
  use Cannery.DataCase

  alias Cannery.ActivityLog

  describe "shot_groups" do
    alias Cannery.ActivityLog.ShotGroup

    import Cannery.ActivityLogFixtures

    @invalid_attrs %{count: nil, date: nil, notes: nil}

    test "list_shot_groups/0 returns all shot_groups" do
      shot_group = shot_group_fixture()
      assert ActivityLog.list_shot_groups() == [shot_group]
    end

    test "get_shot_group!/1 returns the shot_group with given id" do
      shot_group = shot_group_fixture()
      assert ActivityLog.get_shot_group!(shot_group.id) == shot_group
    end

    test "create_shot_group/1 with valid data creates a shot_group" do
      valid_attrs = %{count: 42, date: ~N[2022-02-13 03:17:00], notes: "some notes"}

      assert {:ok, %ShotGroup{} = shot_group} = ActivityLog.create_shot_group(valid_attrs)
      assert shot_group.count == 42
      assert shot_group.date == ~N[2022-02-13 03:17:00]
      assert shot_group.notes == "some notes"
    end

    test "create_shot_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ActivityLog.create_shot_group(@invalid_attrs)
    end

    test "update_shot_group/2 with valid data updates the shot_group" do
      shot_group = shot_group_fixture()
      update_attrs = %{count: 43, date: ~N[2022-02-14 03:17:00], notes: "some updated notes"}

      assert {:ok, %ShotGroup{} = shot_group} =
               ActivityLog.update_shot_group(shot_group, update_attrs)

      assert shot_group.count == 43
      assert shot_group.date == ~N[2022-02-14 03:17:00]
      assert shot_group.notes == "some updated notes"
    end

    test "update_shot_group/2 with invalid data returns error changeset" do
      shot_group = shot_group_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ActivityLog.update_shot_group(shot_group, @invalid_attrs)

      assert shot_group == ActivityLog.get_shot_group!(shot_group.id)
    end

    test "delete_shot_group/1 deletes the shot_group" do
      shot_group = shot_group_fixture()
      assert {:ok, %ShotGroup{}} = ActivityLog.delete_shot_group(shot_group)
      assert_raise Ecto.NoResultsError, fn -> ActivityLog.get_shot_group!(shot_group.id) end
    end

    test "change_shot_group/1 returns a shot_group changeset" do
      shot_group = shot_group_fixture()
      assert %Ecto.Changeset{} = ActivityLog.change_shot_group(shot_group)
    end
  end
end
