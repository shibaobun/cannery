defmodule Cannery.AmmoTest do
  @moduledoc """
  Tests the Ammo context
  """

  use Cannery.DataCase
  alias Cannery.{Ammo, Ammo.AmmoGroup, Ammo.AmmoType, Containers}
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

    test "list_ammo_types/2 returns relevant ammo_types for a user",
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

    test "get_ammo_type!/2 returns the ammo_type with given id",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert Ammo.get_ammo_type!(ammo_type.id, current_user) == ammo_type
    end

    test "create_ammo_type/2 with valid data creates a ammo_type",
         %{current_user: current_user} do
      assert {:ok, %AmmoType{} = ammo_type} = Ammo.create_ammo_type(@valid_attrs, current_user)
      assert ammo_type.bullet_type == "some bullet_type"
      assert ammo_type.case_material == "some case_material"
      assert ammo_type.desc == "some desc"
      assert ammo_type.manufacturer == "some manufacturer"
      assert ammo_type.name == "some name"
      assert ammo_type.grains == 120
    end

    test "create_ammo_type/2 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Ammo.create_ammo_type(@invalid_attrs, current_user)
    end

    test "update_ammo_type/3 with valid data updates the ammo_type",
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

    test "update_ammo_type/3 with invalid data returns error changeset",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert {:error, %Changeset{}} =
               Ammo.update_ammo_type(ammo_type, @invalid_attrs, current_user)

      assert ammo_type == Ammo.get_ammo_type!(ammo_type.id, current_user)
    end

    test "delete_ammo_type/2 deletes the ammo_type",
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

    test "get_average_cost_for_ammo_type/2 gets average cost for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 70.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 40.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 30.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      assert 37.5 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)
    end

    test "get_average_cost_for_ammo_types/2 gets average costs for ammo types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      current_user: current_user,
      container: container
    } do
      assert %{} == [ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      assert %{} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_average_cost_for_ammo_types(current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          another_ammo_type,
          container,
          current_user
        )

      assert %{another_ammo_type_id => 25.0} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_average_cost_for_ammo_types(current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 25.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 70.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 40.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_ammo_group]} =
        ammo_group_fixture(
          %{"price_paid" => 30.00, "count" => 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 37.5} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs
    end

    test "get_round_count_for_ammo_type/2 gets accurate round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      another_ammo_type = ammo_type_fixture(current_user)
      assert 0 = Ammo.get_round_count_for_ammo_type(another_ammo_type, current_user)

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

    test "get_round_count_for_ammo_types/2 gets accurate round counts for ammo types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      current_user: current_user,
      container: container
    } do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      {1, [_another_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, another_ammo_type, container, current_user)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 1} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      shot_group_fixture(%{"count" => 26}, current_user, ammo_group)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 24} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts
    end

    test "get_historical_count_for_ammo_type/2 gets accurate total round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

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

    test "get_historical_count_for_ammo_types/2 gets accurate total round counts for ammo types",
         %{
           ammo_type: %{id: ammo_type_id} = ammo_type,
           current_user: current_user,
           container: container
         } do
      assert %{} == [ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      {1, [_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, another_ammo_type, container, current_user)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 1} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      shot_group_fixture(%{"count" => 26}, current_user, ammo_group)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts
    end

    test "get_used_ammo_groups_count_for_type/2 gets accurate total ammo count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_used_ammo_groups_count_for_type(ammo_type, current_user)

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

    test "get_used_ammo_groups_count_for_types/2 gets accurate total ammo counts for ammo types",
         %{
           ammo_type: %{id: ammo_type_id} = ammo_type,
           current_user: current_user,
           container: container
         } do
      # testing empty ammo type
      assert %{} == [ammo_type] |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      # testing two empty ammo types
      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      assert %{} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      # testing ammo type with ammo group
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)

      assert %{} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      # testing ammo type with used ammo group
      {1, [another_ammo_group]} =
        ammo_group_fixture(%{"count" => 50}, another_ammo_type, container, current_user)

      shot_group_fixture(%{"count" => 50}, current_user, another_ammo_group)

      assert %{another_ammo_type_id => 1} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      # testing two ammo types with zero and one used ammo groups
      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 50}, ammo_type, container, current_user)
      shot_group_fixture(%{"count" => 50}, current_user, ammo_group)

      used_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      assert %{^ammo_type_id => 1} = used_counts
      assert %{^another_ammo_type_id => 1} = used_counts

      # testing two ammo type with one and two used ammo groups
      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)

      used_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_used_ammo_groups_count_for_types(current_user)

      assert %{^ammo_type_id => 2} = used_counts
      assert %{^another_ammo_type_id => 1} = used_counts
    end

    test "get_ammo_groups_count_for_container!/2 gets accurate ammo count for container",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, container, current_user)

      assert 1 = Ammo.get_ammo_groups_count_for_container!(container, current_user)

      {25, _ammo_groups} =
        ammo_group_fixture(%{"count" => 5}, 25, ammo_type, container, current_user)

      assert 26 = Ammo.get_ammo_groups_count_for_container!(container, current_user)

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)
      assert 26 = Ammo.get_ammo_groups_count_for_container!(container, current_user)

      shot_group_fixture(%{"count" => 4}, current_user, first_ammo_group)
      assert 25 = Ammo.get_ammo_groups_count_for_container!(container, current_user)
    end

    test "get_ammo_groups_count_for_containers/2 gets accurate ammo count for containers", %{
      ammo_type: ammo_type,
      current_user: current_user,
      container: %{id: container_id} = container
    } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, container, current_user)

      {1, [_first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, another_container, current_user)

      ammo_groups_count =
        [container, another_container]
        |> Ammo.get_ammo_groups_count_for_containers(current_user)

      assert %{^container_id => 1} = ammo_groups_count
      assert %{^another_container_id => 1} = ammo_groups_count

      {25, _ammo_groups} =
        ammo_group_fixture(%{"count" => 5}, 25, ammo_type, container, current_user)

      ammo_groups_count =
        [container, another_container]
        |> Ammo.get_ammo_groups_count_for_containers(current_user)

      assert %{^container_id => 26} = ammo_groups_count
      assert %{^another_container_id => 1} = ammo_groups_count

      shot_group_fixture(%{"count" => 1}, current_user, first_ammo_group)

      ammo_groups_count =
        [container, another_container]
        |> Ammo.get_ammo_groups_count_for_containers(current_user)

      assert %{^container_id => 26} = ammo_groups_count
      assert %{^another_container_id => 1} = ammo_groups_count

      shot_group_fixture(%{"count" => 4}, current_user, first_ammo_group)

      ammo_groups_count =
        [container, another_container]
        |> Ammo.get_ammo_groups_count_for_containers(current_user)

      assert %{^container_id => 25} = ammo_groups_count
      assert %{^another_container_id => 1} = ammo_groups_count
    end

    test "get_round_count_for_container!/2 gets accurate total round count for container",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, container, current_user)

      assert 5 = Ammo.get_round_count_for_container!(container, current_user)

      {25, _ammo_groups} =
        ammo_group_fixture(%{"count" => 5}, 25, ammo_type, container, current_user)

      assert 130 = Ammo.get_round_count_for_container!(container, current_user)

      shot_group_fixture(%{"count" => 5}, current_user, first_ammo_group)
      assert 125 = Ammo.get_round_count_for_container!(container, current_user)
    end

    test "get_round_count_for_containers/2 gets accurate total round count for containers",
         %{
           ammo_type: ammo_type,
           current_user: current_user,
           container: %{id: container_id} = container
         } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, container, current_user)

      {1, [_first_ammo_group]} =
        ammo_group_fixture(%{"count" => 5}, ammo_type, another_container, current_user)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 5} = round_counts
      assert %{^another_container_id => 5} = round_counts

      {25, _ammo_groups} =
        ammo_group_fixture(%{"count" => 5}, 25, ammo_type, container, current_user)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 130} = round_counts
      assert %{^another_container_id => 5} = round_counts

      shot_group_fixture(%{"count" => 5}, current_user, first_ammo_group)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 125} = round_counts
      assert %{^another_container_id => 5} = round_counts
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

      another_user = user_fixture()
      another_ammo_type = ammo_type_fixture(another_user)
      another_container = container_fixture(another_user)

      {1, [_shouldnt_show_up]} =
        ammo_group_fixture(another_ammo_type, another_container, another_user)

      [
        ammo_type: ammo_type,
        ammo_group: ammo_group,
        container: container,
        current_user: current_user
      ]
    end

    test "list_ammo_groups/3 returns all ammo_groups",
         %{
           ammo_type: ammo_type,
           ammo_group: ammo_group,
           container: container,
           current_user: current_user
         } do
      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(%{"count" => 30}, ammo_type, container, current_user)

      shot_group_fixture(%{"count" => 30}, current_user, another_ammo_group)
      another_ammo_group = Ammo.get_ammo_group!(another_ammo_group_id, current_user)

      assert Ammo.list_ammo_groups(nil, false, current_user) == [ammo_group]

      assert Ammo.list_ammo_groups(nil, true, current_user)
             |> Enum.sort_by(fn %{count: count} -> count end) == [another_ammo_group, ammo_group]
    end

    test "list_ammo_groups/3 returns relevant ammo groups when searched",
         %{
           ammo_type: ammo_type,
           ammo_group: ammo_group,
           container: container,
           current_user: current_user
         } do
      {1, [another_ammo_group]} =
        %{"count" => 49, "notes" => "cool ammo group"}
        |> ammo_group_fixture(ammo_type, container, current_user)

      another_ammo_type = ammo_type_fixture(%{"name" => "amazing ammo"}, current_user)
      another_container = container_fixture(%{"name" => "fantastic container"}, current_user)

      tag = tag_fixture(%{"name" => "stupendous tag"}, current_user)
      Containers.add_tag!(another_container, tag, current_user)

      {1, [amazing_ammo_group]} =
        ammo_group_fixture(%{"count" => 48}, another_ammo_type, container, current_user)

      {1, [fantastic_ammo_group]} =
        ammo_group_fixture(%{"count" => 47}, ammo_type, another_container, current_user)

      assert Ammo.list_ammo_groups(nil, false, current_user)
             |> Enum.sort_by(fn %{count: count} -> count end) ==
               [fantastic_ammo_group, amazing_ammo_group, another_ammo_group, ammo_group]

      # search works for ammo group attributes
      assert Ammo.list_ammo_groups("cool", true, current_user) == [another_ammo_group]

      # search works for ammo type attributes
      assert Ammo.list_ammo_groups("amazing", true, current_user) == [amazing_ammo_group]

      # search works for container attributes
      assert Ammo.list_ammo_groups("fantastic", true, current_user) == [fantastic_ammo_group]

      # search works for container tag attributes
      assert Ammo.list_ammo_groups("stupendous", true, current_user) == [fantastic_ammo_group]

      assert Ammo.list_ammo_groups("random", true, current_user) == []
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

      assert Ammo.list_ammo_groups_for_type(ammo_type, current_user) == [ammo_group]
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

      assert Ammo.list_ammo_groups_for_container(container, current_user) == [ammo_group]
    end

    test "get_ammo_groups_count_for_type/2 returns count of ammo_groups for a type", %{
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert 1 = Ammo.get_ammo_groups_count_for_type(ammo_type, current_user)

      another_ammo_type = ammo_type_fixture(current_user)
      assert 0 = Ammo.get_ammo_groups_count_for_type(another_ammo_type, current_user)

      {5, _ammo_groups} = ammo_group_fixture(%{}, 5, ammo_type, container, current_user)
      assert 6 = Ammo.get_ammo_groups_count_for_type(ammo_type, current_user)
    end

    test "get_ammo_groups_count_for_types/2 returns counts of ammo_groups for types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      container: container,
      current_user: current_user
    } do
      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_ammo_groups_count_for_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_ammo_groups_count_for_types(current_user)

      {1, [_ammo_group]} = ammo_group_fixture(another_ammo_type, container, current_user)

      ammo_groups_count =
        [ammo_type, another_ammo_type] |> Ammo.get_ammo_groups_count_for_types(current_user)

      assert %{^ammo_type_id => 1} = ammo_groups_count
      assert %{^another_ammo_type_id => 1} = ammo_groups_count

      {5, _ammo_groups} = ammo_group_fixture(%{}, 5, ammo_type, container, current_user)

      ammo_groups_count =
        [ammo_type, another_ammo_type] |> Ammo.get_ammo_groups_count_for_types(current_user)

      assert %{^ammo_type_id => 6} = ammo_groups_count
      assert %{^another_ammo_type_id => 1} = ammo_groups_count
    end

    test "list_staged_ammo_groups/1 returns all ammo_groups that are staged",
         %{
           ammo_type: ammo_type,
           container: container,
           current_user: current_user
         } do
      {1, [another_ammo_group]} =
        ammo_group_fixture(%{"staged" => true}, ammo_type, container, current_user)

      assert Ammo.list_staged_ammo_groups(current_user) == [another_ammo_group]
    end

    test "get_ammo_group!/2 returns the ammo_group with given id",
         %{ammo_group: %{id: ammo_group_id} = ammo_group, current_user: current_user} do
      assert Ammo.get_ammo_group!(ammo_group_id, current_user) == ammo_group
    end

    test "get_ammo_groups/2 returns the ammo_groups with given id", %{
      ammo_group: %{id: ammo_group_id} = ammo_group,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(ammo_type, container, current_user)

      ammo_groups = Ammo.get_ammo_groups([ammo_group_id, another_ammo_group_id], current_user)
      assert %{^ammo_group_id => ^ammo_group} = ammo_groups
      assert %{^another_ammo_group_id => ^another_ammo_group} = ammo_groups
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

    test "update_ammo_group/3 with valid data updates the ammo_group",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:ok, %AmmoGroup{} = ammo_group} =
               Ammo.update_ammo_group(ammo_group, @update_attrs, current_user)

      assert ammo_group.count == 43
      assert ammo_group.notes == "some updated notes"
      assert ammo_group.price_paid == 456.7
    end

    test "update_ammo_group/3 with invalid data returns error changeset",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:error, %Changeset{}} =
               Ammo.update_ammo_group(ammo_group, @invalid_attrs, current_user)

      assert ammo_group == Ammo.get_ammo_group!(ammo_group.id, current_user)
    end

    test "delete_ammo_group/2 deletes the ammo_group",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert {:ok, %AmmoGroup{}} = Ammo.delete_ammo_group(ammo_group, current_user)
      assert_raise KeyError, fn -> Ammo.get_ammo_group!(ammo_group.id, current_user) end
    end

    test "get_percentage_remaining/2 gets accurate total round count",
         %{ammo_group: %{id: ammo_group_id} = ammo_group, current_user: current_user} do
      assert 100 = ammo_group |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 72 = ammo_group |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 50 = ammo_group |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 0 = ammo_group |> Ammo.get_percentage_remaining(current_user)
    end

    test "get_percentages_remaining/2 gets accurate total round count", %{
      ammo_group: %{id: ammo_group_id} = ammo_group,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert %{ammo_group_id => 100} ==
               [ammo_group] |> Ammo.get_percentages_remaining(current_user)

      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        %{"count" => 50, "price_paid" => 36.1}
        |> ammo_group_fixture(ammo_type, container, current_user)

      percentages =
        [ammo_group, another_ammo_group] |> Ammo.get_percentages_remaining(current_user)

      assert %{^ammo_group_id => 100} = percentages
      assert %{^another_ammo_group_id => 100} = percentages

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)

      percentages =
        [ammo_group, another_ammo_group] |> Ammo.get_percentages_remaining(current_user)

      assert %{^ammo_group_id => 72} = percentages
      assert %{^another_ammo_group_id => 100} = percentages

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)

      percentages =
        [ammo_group, another_ammo_group] |> Ammo.get_percentages_remaining(current_user)

      assert %{^ammo_group_id => 50} = percentages
      assert %{^another_ammo_group_id => 100} = percentages

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)

      percentages =
        [ammo_group, another_ammo_group] |> Ammo.get_percentages_remaining(current_user)

      assert %{^ammo_group_id => 0} = percentages
      assert %{^another_ammo_group_id => 100} = percentages
    end

    test "get_cpr/2 gets accurate cpr",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)
      assert ammo_group |> Ammo.get_cpr(current_user) |> is_nil()

      {1, [ammo_group]} =
        ammo_group_fixture(
          %{"count" => 1, "price_paid" => 1.0},
          ammo_type,
          container,
          current_user
        )

      assert 1.0 = ammo_group |> Ammo.get_cpr(current_user)

      {1, [ammo_group]} =
        ammo_group_fixture(
          %{"count" => 2, "price_paid" => 3.0},
          ammo_type,
          container,
          current_user
        )

      assert 1.5 = ammo_group |> Ammo.get_cpr(current_user)

      {1, [ammo_group]} =
        ammo_group_fixture(
          %{"count" => 50, "price_paid" => 36.1},
          ammo_type,
          container,
          current_user
        )

      assert 0.722 = ammo_group |> Ammo.get_cpr(current_user)

      # with shot group, maintains total
      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group.id, current_user)
      assert 0.722 = ammo_group |> Ammo.get_cpr(current_user)
    end

    test "get_cprs/2 gets accurate cprs",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      {1, [ammo_group]} = ammo_group_fixture(%{"count" => 1}, ammo_type, container, current_user)
      assert %{} == [ammo_group] |> Ammo.get_cprs(current_user)

      {1, [%{id: ammo_group_id} = ammo_group]} =
        ammo_group_fixture(
          %{"count" => 1, "price_paid" => 1.0},
          ammo_type,
          container,
          current_user
        )

      assert %{ammo_group_id => 1.0} == [ammo_group] |> Ammo.get_cprs(current_user)

      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(
          %{"count" => 2, "price_paid" => 3.0},
          ammo_type,
          container,
          current_user
        )

      cprs = [ammo_group, another_ammo_group] |> Ammo.get_cprs(current_user)
      assert %{^ammo_group_id => 1.0} = cprs
      assert %{^another_ammo_group_id => 1.5} = cprs

      {1, [%{id: yet_another_ammo_group_id} = yet_another_ammo_group]} =
        ammo_group_fixture(
          %{"count" => 50, "price_paid" => 36.1},
          ammo_type,
          container,
          current_user
        )

      cprs =
        [ammo_group, another_ammo_group, yet_another_ammo_group] |> Ammo.get_cprs(current_user)

      assert %{^ammo_group_id => 1.0} = cprs
      assert %{^another_ammo_group_id => 1.5} = cprs
      assert %{^yet_another_ammo_group_id => 0.722} = cprs

      # with shot group, maintains total
      shot_group_fixture(%{"count" => 14}, current_user, yet_another_ammo_group)
      yet_another_ammo_group = Ammo.get_ammo_group!(yet_another_ammo_group.id, current_user)

      cprs =
        [ammo_group, another_ammo_group, yet_another_ammo_group] |> Ammo.get_cprs(current_user)

      assert %{^ammo_group_id => 1.0} = cprs
      assert %{^another_ammo_group_id => 1.5} = cprs
      assert %{^yet_another_ammo_group_id => 0.722} = cprs
    end

    test "get_original_count/2 gets accurate original count",
         %{ammo_group: %{id: ammo_group_id} = ammo_group, current_user: current_user} do
      assert 50 = ammo_group |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 50 = ammo_group |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 50 = ammo_group |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      assert 50 = ammo_group |> Ammo.get_original_count(current_user)
    end

    test "get_original_counts/2 gets accurate original counts", %{
      ammo_group: %{id: ammo_group_id} = ammo_group,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_ammo_group_id} = another_ammo_group]} =
        ammo_group_fixture(%{"count" => 25}, ammo_type, container, current_user)

      original_counts = [ammo_group, another_ammo_group] |> Ammo.get_original_counts(current_user)
      assert %{^ammo_group_id => 50} = original_counts
      assert %{^another_ammo_group_id => 25} = original_counts

      shot_group_fixture(%{"count" => 14}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      original_counts = [ammo_group, another_ammo_group] |> Ammo.get_original_counts(current_user)
      assert %{^ammo_group_id => 50} = original_counts
      assert %{^another_ammo_group_id => 25} = original_counts

      shot_group_fixture(%{"count" => 11}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      original_counts = [ammo_group, another_ammo_group] |> Ammo.get_original_counts(current_user)
      assert %{^ammo_group_id => 50} = original_counts
      assert %{^another_ammo_group_id => 25} = original_counts

      shot_group_fixture(%{"count" => 25}, current_user, ammo_group)
      ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
      original_counts = [ammo_group, another_ammo_group] |> Ammo.get_original_counts(current_user)
      assert %{^ammo_group_id => 50} = original_counts
      assert %{^another_ammo_group_id => 25} = original_counts
    end
  end
end
