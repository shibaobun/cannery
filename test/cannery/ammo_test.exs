defmodule Cannery.AmmoTest do
  @moduledoc """
  Tests the Ammo context
  """

  use Cannery.DataCase
  alias Cannery.{Ammo, Ammo.AmmoGroup, Ammo.AmmoType}
  alias Ecto.Changeset

  @moduletag :ammo_test

  describe "ammo_types" do
    @valid_attrs %{
      "bullet_type" => "some bullet_type",
      "case_material" => "some case_material",
      "desc" => "some desc",
      "manufacturer" => "some manufacturer",
      "name" => "some name",
      "grains" => 120
    }
    @update_attrs %{
      "bullet_type" => "some updated bullet_type",
      "case_material" => "some updated case_material",
      "desc" => "some updated desc",
      "manufacturer" => "some updated manufacturer",
      "name" => "some updated name",
      "grains" => 456
    }
    @invalid_attrs %{
      "bullet_type" => nil,
      "case_material" => nil,
      "desc" => nil,
      "manufacturer" => nil,
      "name" => nil,
      "grains" => nil
    }

    setup do
      current_user = user_fixture()
      [ammo_type: ammo_type_fixture(current_user), current_user: current_user]
    end

    test "list_ammo_types/1 returns all ammo_types",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert Ammo.list_ammo_types(current_user) == [ammo_type]
    end

    test "list_ammo_types/1 returns relevant ammo_types for a user",
         %{current_user: current_user} do
      ammo_type_a =
        %{"name" => "bullets", "desc" => "has some pews in it", "grains" => 5}
        |> ammo_type_fixture(current_user)

      ammo_type_b =
        %{"name" => "hollows", "grains" => 3}
        |> ammo_type_fixture(current_user)

      ammo_type_c =
        %{
          "name" => "jackets",
          "desc" => "brass shell",
          "tracer" => true
        }
        |> ammo_type_fixture(current_user)

      _shouldnt_return =
        %{
          "name" => "bullet",
          "desc" => "pews brass shell"
        }
        |> ammo_type_fixture(user_fixture())

      # name
      assert Ammo.list_ammo_types("bullet", current_user) == [ammo_type_a]
      assert Ammo.list_ammo_types("bullets", current_user) == [ammo_type_a]
      assert Ammo.list_ammo_types("hollow", current_user) == [ammo_type_b]
      assert Ammo.list_ammo_types("jacket", current_user) == [ammo_type_c]

      # desc
      assert Ammo.list_ammo_types("pew", current_user) == [ammo_type_a]
      assert Ammo.list_ammo_types("brass", current_user) == [ammo_type_c]
      assert Ammo.list_ammo_types("shell", current_user) == [ammo_type_c]

      # grains (integer)
      assert Ammo.list_ammo_types("5", current_user) == [ammo_type_a]
      assert Ammo.list_ammo_types("3", current_user) == [ammo_type_b]

      # tracer (boolean)
      assert Ammo.list_ammo_types("tracer", current_user) == [ammo_type_c]
    end

    test "get_ammo_type!/1 returns the ammo_type with given id",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert Ammo.get_ammo_type!(ammo_type.id, current_user) == ammo_type
    end

    test "create_ammo_type/1 with valid data creates a ammo_type",
         %{current_user: current_user} do
      assert {:ok, %AmmoType{} = ammo_type} = Ammo.create_ammo_type(@valid_attrs, current_user)
      assert ammo_type.bullet_type == "some bullet_type"
      assert ammo_type.case_material == "some case_material"
      assert ammo_type.desc == "some desc"
      assert ammo_type.manufacturer == "some manufacturer"
      assert ammo_type.name == "some name"
      assert ammo_type.grains == 120
    end

    test "create_ammo_type/1 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Ammo.create_ammo_type(@invalid_attrs, current_user)
    end

    test "update_ammo_type/2 with valid data updates the ammo_type",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert {:ok, %AmmoType{} = ammo_type} =
               Ammo.update_ammo_type(ammo_type, @update_attrs, current_user)

      assert ammo_type.bullet_type == "some updated bullet_type"
      assert ammo_type.case_material == "some updated case_material"
      assert ammo_type.desc == "some updated desc"
      assert ammo_type.manufacturer == "some updated manufacturer"
      assert ammo_type.name == "some updated name"
      assert ammo_type.grains == 456
    end

    test "update_ammo_type/2 with invalid data returns error changeset",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert {:error, %Changeset{}} =
               Ammo.update_ammo_type(ammo_type, @invalid_attrs, current_user)

      assert ammo_type == Ammo.get_ammo_type!(ammo_type.id, current_user)
    end

    test "delete_ammo_type/1 deletes the ammo_type",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert {:ok, %AmmoType{}} = Ammo.delete_ammo_type(ammo_type, current_user)
      assert_raise Ecto.NoResultsError, fn -> Ammo.get_ammo_type!(ammo_type.id, current_user) end
    end
  end

  describe "ammo types with ammo groups" do
    setup do
      current_user = user_fixture()
      ammo_type = ammo_type_fixture(current_user)
      container = container_fixture(current_user)

      [
        ammo_type: ammo_type,
        container: container,
        current_user: current_user
      ]
    end

    test "get_average_cost_for_ammo_type!/2 gets average cost for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type!(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type!(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 70.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 40.0 = Ammo.get_average_cost_for_ammo_type!(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 30.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 37.5 = Ammo.get_average_cost_for_ammo_type!(ammo_type, current_user)
    end

    test "get_round_count_for_ammo_type/2 gets accurate round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert 1 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      assert 51 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 26}, current_user, ammo_group)
      assert 25 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)
      assert 24 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)
    end

    test "get_used_count_for_ammo_type/2 gets accurate used round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_count_for_ammo_type(ammo_type, current_user)

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 26}, current_user, ammo_group)
      assert 26 = Ammo.get_used_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)
      assert 27 = Ammo.get_used_count_for_ammo_type(ammo_type, current_user)
    end

    test "get_historical_count_for_ammo_type/2 gets accurate total round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert 1 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 26}, current_user, ammo_group)
      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)
      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)
    end

    test "get_used_ammo_groups_count_for_type/2 gets accurate total ammo count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_ammo_groups_count_for_type(ammo_type, current_user)

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_ammo_groups_count_for_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 50}, current_user, ammo_group)
      assert 1 = Ammo.get_used_ammo_groups_count_for_type(ammo_type, current_user)

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)
      assert 2 = Ammo.get_used_ammo_groups_count_for_type(ammo_type, current_user)
    end
  end

  describe "ammo_groups" do
    @valid_attrs %{
      "count" => 42,
      "notes" => "some notes",
      "price_paid" => 120.5,
      "purchased_on" => ~D[2022-11-19]
    }
    @update_attrs %{
      "count" => 43,
      "notes" => "some updated notes",
      "price_paid" => 456.7
    }
    @invalid_attrs %{
      "count" => nil,
      "notes" => nil,
      "price_paid" => nil
    }

    setup do
      current_user = user_fixture()
      ammo_type = ammo_type_fixture(current_user)
      container = container_fixture(current_user)

      {1, [ammo_group]} =
        %{"count" => 50, "price_paid" => 36.1}
        |> ammo_group_fixture(ammo_type, container, current_user)

      [
        ammo_type: ammo_type,
        ammo_group: ammo_group,
        container: container,
        current_user: current_user
      ]
    end

    test "list_ammo_groups/2 returns all ammo_groups",
         %{
           ammo_type: ammo_type,
           ammo_group: ammo_group,
           container: container,
           current_user: current_user
         } do
      {1, [another_ammo_group]} =
        ammo_group_fixture(%{"count" => 30}, ammo_type, container, current_user)

      shot_group_fixture(%{"count" => 30}, current_user, another_ammo_group)
      another_ammo_group = another_ammo_group |> Repo.reload!()
      assert Ammo.list_ammo_groups(current_user) == [ammo_group] |> Repo.preload(:shot_groups)

      assert Ammo.list_ammo_groups(current_user, true)
             |> Enum.sort_by(fn %{count: count} -> count end) ==
               [another_ammo_group, ammo_group] |> Repo.preload(:shot_groups)
    end

    test "list_ammo_groups_for_type/2 returns all ammo_groups for a type",
         %{
           ammo_type: ammo_type,
           container: container,
           ammo_group: ammo_group,
           current_user: current_user
         } do
      another_ammo_type = ammo_type_fixture(current_user)
      {1, [_another]} = ammo_group_fixture(another_ammo_type, container, current_user)

      assert Ammo.list_ammo_groups_for_type(ammo_type, current_user) ==
               [ammo_group] |> Repo.preload(:shot_groups)
    end

    test "list_ammo_groups_for_container/2 returns all ammo_groups for a container",
         %{
           ammo_type: ammo_type,
           container: container,
           ammo_group: ammo_group,
           current_user: current_user
         } do
      another_container = container_fixture(current_user)
      {1, [_another]} = ammo_group_fixture(ammo_type, another_container, current_user)

      assert Ammo.list_ammo_groups_for_container(container, current_user) ==
               [ammo_group] |> Repo.preload(:shot_groups)
    end

    test "get_ammo_groups_count_for_type/2 returns count of ammo_groups for a type",
         %{
           ammo_type: ammo_type,
           container: container,
           current_user: current_user
         } do
      another_ammo_type = ammo_type_fixture(current_user)
      {1, [_another]} = ammo_group_fixture(another_ammo_type, container, current_user)

      assert 1 = Ammo.get_ammo_groups_count_for_type(ammo_type, current_user)
    end

    test "list_staged_ammo_groups/2 returns all ammo_groups that are staged",
         %{
           ammo_type: ammo_type,
           container: container,
           current_user: current_user
         } do
      {1, [another_ammo_group]} =
        ammo_group_fixture(%{"staged" => true}, ammo_type, container, current_user)

      assert Ammo.list_staged_ammo_groups(current_user) ==
               [another_ammo_group] |> Repo.preload(:shot_groups)
    end

    test "get_ammo_group!/1 returns the ammo_group with given id",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert Ammo.get_ammo_group!(ammo_group.id, current_user) ==
               ammo_group |> Repo.preload(:shot_groups)
    end

    test "create_ammo_groups/3 with valid data creates a ammo_group",
         %{
           ammo_type: ammo_type,
           container: container,
           current_user: current_user
         } do
      assert {:ok, {1, [%AmmoGroup{} = ammo_group]}} =
               @valid_attrs
               |> Map.merge(%{"ammo_type_id" => ammo_type.id, "container_id" => container.id})
               |> Ammo.create_ammo_groups(1, current_user)

      assert ammo_group.count == 42
      assert ammo_group.notes == "some notes"
      assert ammo_group.price_paid == 120.5
    end

    test "create_ammo_groups/3 with valid data creates multiple ammo_groups",
         %{
           ammo_type: ammo_type,
           container: container,
           current_user: current_user
         } do
      assert {:ok, {3, ammo_groups}} =
               @valid_attrs
               |> Map.merge(%{"ammo_type_id" => ammo_type.id, "container_id" => container.id})
               |> Ammo.create_ammo_groups(3, current_user)

      assert [%AmmoGroup{}, %AmmoGroup{}, %AmmoGroup{}] = ammo_groups

      ammo_groups
      |> Enum.map(fn %{count: count, notes: notes, price_paid: price_paid} ->
        assert count == 42
        assert notes == "some notes"
        assert price_paid == 120.5
      end)
    end

    test "create_ammo_groups/3 with invalid data returns error changeset",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      assert {:error, %Changeset{}} =
               @invalid_attrs
               |> Map.merge(%{"ammo_type_id" => ammo_type.id, "container_id" => container.id})
               |> Ammo.create_ammo_groups(1, current_user)
    end

    test "update_ammo_group/2 with valid data updates the ammo_group",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:ok, %AmmoGroup{} = ammo_group} =
               Ammo.update_ammo_group(ammo_group, @update_attrs, current_user)

      assert ammo_group.count == 43
      assert ammo_group.notes == "some updated notes"
      assert ammo_group.price_paid == 456.7
    end

    test "update_ammo_group/2 with invalid data returns error changeset",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:error, %Changeset{}} =
               Ammo.update_ammo_group(ammo_group, @invalid_attrs, current_user)

      assert ammo_group |> Repo.preload(:shot_groups) ==
               Ammo.get_ammo_group!(ammo_group.id, current_user)
    end

    test "delete_ammo_group/1 deletes the ammo_group",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:ok, %AmmoGroup{}} = Ammo.delete_ammo_group(ammo_group, current_user)

      assert_raise Ecto.NoResultsError, fn ->
        Ammo.get_ammo_group!(ammo_group.id, current_user)
      end
    end

    test "get_used_count/1 returns accurate used count",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert 0 = Ammo.get_used_count(ammo_group)
      shot_group_fixture(%{"count" => 15}, current_user, ammo_group)
      assert 15 = ammo_group |> Repo.preload(:shot_groups, force: true) |> Ammo.get_used_count()
      shot_group_fixture(%{"count" => 10}, current_user, ammo_group)
      assert 25 = ammo_group |> Repo.preload(:shot_groups, force: true) |> Ammo.get_used_count()
    end

    test "get_last_used_shot_group/1 returns accurate used count",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert ammo_group
             |> Repo.preload(:shot_groups, force: true)
             |> Ammo.get_last_used_shot_group()
             |> is_nil()

      shot_group = shot_group_fixture(%{"date" => ~D[2022-11-10]}, current_user, ammo_group)

      assert ^shot_group =
               ammo_group
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_last_used_shot_group()

      shot_group = shot_group_fixture(%{"date" => ~D[2022-11-11]}, current_user, ammo_group)

      assert ^shot_group =
               ammo_group
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_last_used_shot_group()
    end

    test "get_percentage_remaining/1 gets accurate total round count",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert 100 = Ammo.get_percentage_remaining(ammo_group)

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)

      assert 72 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_percentage_remaining()

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)

      assert 50 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_percentage_remaining()

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)

      assert 0 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_percentage_remaining()
    end

    test "get_cpr/1 gets accurate cpr",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert %AmmoGroup{price_paid: nil} |> Ammo.get_cpr() |> is_nil()
      assert %AmmoGroup{count: 1, price_paid: nil} |> Ammo.get_cpr() |> is_nil()
      assert 1.0 = %AmmoGroup{count: 1, price_paid: 1.0} |> Ammo.get_cpr()
      assert 1.5 = %AmmoGroup{count: 2, price_paid: 3.0} |> Ammo.get_cpr()
      assert 0.722 = %AmmoGroup{count: 50, price_paid: 36.1} |> Ammo.get_cpr()

      # with shot group, maintains total
      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)

      assert 0.722 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_cpr()
    end

    test "get_original_count/1 gets accurate original count",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert 50 = Ammo.get_original_count(ammo_group)

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)

      assert 50 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_original_count()

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)

      assert 50 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_original_count()

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)

      assert 50 =
               ammo_group
               |> Repo.reload!()
               |> Repo.preload(:shot_groups, force: true)
               |> Ammo.get_original_count()
    end
  end
end
