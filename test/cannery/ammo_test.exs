defmodule Cannery.AmmoTest do
  @moduledoc """
  Tests the Ammo context
  """

  use Cannery.DataCase
  alias Cannery.{Ammo, Ammo.Pack, Ammo.AmmoType, Containers}
  alias Ecto.Changeset

  @moduletag :ammo_test

  @valid_attrs %{
    bullet_type: "some bullet_type",
    case_material: "some case_material",
    desc: "some desc",
    manufacturer: "some manufacturer",
    name: "some name",
    grains: 120
  }
  @update_attrs %{
    bullet_type: "some updated bullet_type",
    case_material: "some updated case_material",
    desc: "some updated desc",
    manufacturer: "some updated manufacturer",
    name: "some updated name",
    grains: 456
  }
  @invalid_attrs %{
    bullet_type: nil,
    case_material: nil,
    desc: nil,
    manufacturer: nil,
    name: nil,
    grains: nil
  }

  describe "list_ammo_types/2" do
    setup do
      current_user = user_fixture()

      rifle_ammo_type =
        %{
          name: "bullets",
          class: :rifle,
          desc: "has some pews in it",
          grains: 5
        }
        |> ammo_type_fixture(current_user)

      shotgun_ammo_type =
        %{
          name: "hollows",
          class: :shotgun,
          grains: 3
        }
        |> ammo_type_fixture(current_user)

      pistol_ammo_type =
        %{
          class: :pistol,
          name: "jackets",
          desc: "brass shell",
          tracer: true
        }
        |> ammo_type_fixture(current_user)

      _shouldnt_return =
        %{
          name: "bullet",
          desc: "pews brass shell"
        }
        |> ammo_type_fixture(user_fixture())

      [
        rifle_ammo_type: rifle_ammo_type,
        shotgun_ammo_type: shotgun_ammo_type,
        pistol_ammo_type: pistol_ammo_type,
        current_user: current_user
      ]
    end

    test "list_ammo_types/2 returns all ammo_types", %{
      rifle_ammo_type: rifle_ammo_type,
      shotgun_ammo_type: shotgun_ammo_type,
      pistol_ammo_type: pistol_ammo_type,
      current_user: current_user
    } do
      results = Ammo.list_ammo_types(current_user, :all)
      assert results |> Enum.count() == 3
      assert rifle_ammo_type in results
      assert shotgun_ammo_type in results
      assert pistol_ammo_type in results
    end

    test "list_ammo_types/2 returns rifle ammo_types", %{
      rifle_ammo_type: rifle_ammo_type,
      current_user: current_user
    } do
      assert [^rifle_ammo_type] = Ammo.list_ammo_types(current_user, :rifle)
    end

    test "list_ammo_types/2 returns shotgun ammo_types", %{
      shotgun_ammo_type: shotgun_ammo_type,
      current_user: current_user
    } do
      assert [^shotgun_ammo_type] = Ammo.list_ammo_types(current_user, :shotgun)
    end

    test "list_ammo_types/2 returns pistol ammo_types", %{
      pistol_ammo_type: pistol_ammo_type,
      current_user: current_user
    } do
      assert [^pistol_ammo_type] = Ammo.list_ammo_types(current_user, :pistol)
    end

    test "list_ammo_types/2 returns relevant ammo_types for a user", %{
      rifle_ammo_type: rifle_ammo_type,
      shotgun_ammo_type: shotgun_ammo_type,
      pistol_ammo_type: pistol_ammo_type,
      current_user: current_user
    } do
      # name
      assert Ammo.list_ammo_types("bullet", current_user, :all) == [rifle_ammo_type]
      assert Ammo.list_ammo_types("bullets", current_user, :all) == [rifle_ammo_type]
      assert Ammo.list_ammo_types("hollow", current_user, :all) == [shotgun_ammo_type]
      assert Ammo.list_ammo_types("jacket", current_user, :all) == [pistol_ammo_type]

      # desc
      assert Ammo.list_ammo_types("pew", current_user, :all) == [rifle_ammo_type]
      assert Ammo.list_ammo_types("brass", current_user, :all) == [pistol_ammo_type]
      assert Ammo.list_ammo_types("shell", current_user, :all) == [pistol_ammo_type]

      # grains (integer)
      assert Ammo.list_ammo_types("5", current_user, :all) == [rifle_ammo_type]
      assert Ammo.list_ammo_types("3", current_user, :all) == [shotgun_ammo_type]

      # tracer (boolean)
      assert Ammo.list_ammo_types("tracer", current_user, :all) == [pistol_ammo_type]
    end
  end

  describe "ammo types" do
    setup do
      current_user = user_fixture()
      [ammo_type: ammo_type_fixture(current_user), current_user: current_user]
    end

    test "get_ammo_type!/2 returns the ammo_type with given id",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert Ammo.get_ammo_type!(ammo_type.id, current_user) == ammo_type
    end

    test "get_ammo_types_count!/1 returns the correct amount of ammo",
         %{current_user: current_user} do
      assert Ammo.get_ammo_types_count!(current_user) == 1

      ammo_type_fixture(current_user)
      assert Ammo.get_ammo_types_count!(current_user) == 2

      ammo_type_fixture(current_user)
      assert Ammo.get_ammo_types_count!(current_user) == 3

      other_user = user_fixture()
      assert Ammo.get_ammo_types_count!(other_user) == 0

      ammo_type_fixture(other_user)
      assert Ammo.get_ammo_types_count!(other_user) == 1
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
      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 70.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      assert 40.0 = Ammo.get_average_cost_for_ammo_type(ammo_type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 30.00, count: 1},
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

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          another_ammo_type,
          container,
          current_user
        )

      assert %{another_ammo_type_id => 25.0} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_average_cost_for_ammo_types(current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 70.00, count: 1},
          ammo_type,
          container,
          current_user
        )

      average_costs =
        [ammo_type, another_ammo_type] |> Ammo.get_average_cost_for_ammo_types(current_user)

      assert %{^ammo_type_id => 40.0} = average_costs
      assert %{^another_ammo_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 30.00, count: 1},
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

      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert 1 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)

      assert 51 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{count: 26}, current_user, pack)
      assert 25 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{count: 1}, current_user, first_pack)
      assert 24 = Ammo.get_round_count_for_ammo_type(ammo_type, current_user)
    end

    test "get_round_count_for_ammo_types/2 gets accurate round counts for ammo types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      current_user: current_user,
      container: container
    } do
      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      {1, [_another_pack]} = pack_fixture(%{count: 1}, another_ammo_type, container, current_user)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 1} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      shot_group_fixture(%{count: 26}, current_user, pack)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 25} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts

      shot_group_fixture(%{count: 1}, current_user, first_pack)

      round_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_round_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 24} = round_counts
      assert %{^another_ammo_type_id => 1} = round_counts
    end

    test "get_historical_count_for_ammo_type/2 gets accurate total round count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert 1 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)

      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{count: 26}, current_user, pack)
      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)

      shot_group_fixture(%{count: 1}, current_user, first_pack)
      assert 51 = Ammo.get_historical_count_for_ammo_type(ammo_type, current_user)
    end

    test "get_historical_count_for_ammo_types/2 gets accurate total round counts for ammo types",
         %{
           ammo_type: %{id: ammo_type_id} = ammo_type,
           current_user: current_user,
           container: container
         } do
      assert %{} == [ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      {1, [_pack]} = pack_fixture(%{count: 1}, another_ammo_type, container, current_user)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 1} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      shot_group_fixture(%{count: 26}, current_user, pack)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts

      shot_group_fixture(%{count: 1}, current_user, first_pack)

      historical_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_historical_count_for_ammo_types(current_user)

      assert %{^ammo_type_id => 51} = historical_counts
      assert %{^another_ammo_type_id => 1} = historical_counts
    end

    test "get_used_packs_count_for_type/2 gets accurate total ammo count for ammo type",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_used_packs_count_for_type(ammo_type, current_user)

      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_packs_count_for_type(ammo_type, current_user)

      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)

      assert 0 = Ammo.get_used_packs_count_for_type(ammo_type, current_user)

      shot_group_fixture(%{count: 50}, current_user, pack)
      assert 1 = Ammo.get_used_packs_count_for_type(ammo_type, current_user)

      shot_group_fixture(%{count: 1}, current_user, first_pack)
      assert 2 = Ammo.get_used_packs_count_for_type(ammo_type, current_user)
    end

    test "get_used_packs_count_for_types/2 gets accurate total ammo counts for ammo types",
         %{
           ammo_type: %{id: ammo_type_id} = ammo_type,
           current_user: current_user,
           container: container
         } do
      # testing empty ammo type
      assert %{} == [ammo_type] |> Ammo.get_used_packs_count_for_types(current_user)

      # testing two empty ammo types
      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      assert %{} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_packs_count_for_types(current_user)

      # testing ammo type with ammo group
      {1, [first_pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)

      assert %{} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_packs_count_for_types(current_user)

      # testing ammo type with used ammo group
      {1, [another_pack]} = pack_fixture(%{count: 50}, another_ammo_type, container, current_user)

      shot_group_fixture(%{count: 50}, current_user, another_pack)

      assert %{another_ammo_type_id => 1} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_used_packs_count_for_types(current_user)

      # testing two ammo types with zero and one used ammo groups
      {1, [pack]} = pack_fixture(%{count: 50}, ammo_type, container, current_user)
      shot_group_fixture(%{count: 50}, current_user, pack)

      used_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_used_packs_count_for_types(current_user)

      assert %{^ammo_type_id => 1} = used_counts
      assert %{^another_ammo_type_id => 1} = used_counts

      # testing two ammo type with one and two used ammo groups
      shot_group_fixture(%{count: 1}, current_user, first_pack)

      used_counts =
        [ammo_type, another_ammo_type] |> Ammo.get_used_packs_count_for_types(current_user)

      assert %{^ammo_type_id => 2} = used_counts
      assert %{^another_ammo_type_id => 1} = used_counts
    end

    test "get_packs_count_for_container!/2 gets accurate ammo count for container",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_pack]} = pack_fixture(%{count: 5}, ammo_type, container, current_user)

      assert 1 = Ammo.get_packs_count_for_container!(container, current_user)

      {25, _packs} = pack_fixture(%{count: 5}, 25, ammo_type, container, current_user)

      assert 26 = Ammo.get_packs_count_for_container!(container, current_user)

      shot_group_fixture(%{count: 1}, current_user, first_pack)
      assert 26 = Ammo.get_packs_count_for_container!(container, current_user)

      shot_group_fixture(%{count: 4}, current_user, first_pack)
      assert 25 = Ammo.get_packs_count_for_container!(container, current_user)
    end

    test "get_packs_count_for_containers/2 gets accurate ammo count for containers", %{
      ammo_type: ammo_type,
      current_user: current_user,
      container: %{id: container_id} = container
    } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 5}, ammo_type, container, current_user)

      {1, [_first_pack]} = pack_fixture(%{count: 5}, ammo_type, another_container, current_user)

      packs_count =
        [container, another_container]
        |> Ammo.get_packs_count_for_containers(current_user)

      assert %{^container_id => 1} = packs_count
      assert %{^another_container_id => 1} = packs_count

      {25, _packs} = pack_fixture(%{count: 5}, 25, ammo_type, container, current_user)

      packs_count =
        [container, another_container]
        |> Ammo.get_packs_count_for_containers(current_user)

      assert %{^container_id => 26} = packs_count
      assert %{^another_container_id => 1} = packs_count

      shot_group_fixture(%{count: 1}, current_user, first_pack)

      packs_count =
        [container, another_container]
        |> Ammo.get_packs_count_for_containers(current_user)

      assert %{^container_id => 26} = packs_count
      assert %{^another_container_id => 1} = packs_count

      shot_group_fixture(%{count: 4}, current_user, first_pack)

      packs_count =
        [container, another_container]
        |> Ammo.get_packs_count_for_containers(current_user)

      assert %{^container_id => 25} = packs_count
      assert %{^another_container_id => 1} = packs_count
    end

    test "get_round_count_for_container!/2 gets accurate total round count for container",
         %{ammo_type: ammo_type, current_user: current_user, container: container} do
      {1, [first_pack]} = pack_fixture(%{count: 5}, ammo_type, container, current_user)

      assert 5 = Ammo.get_round_count_for_container!(container, current_user)

      {25, _packs} = pack_fixture(%{count: 5}, 25, ammo_type, container, current_user)

      assert 130 = Ammo.get_round_count_for_container!(container, current_user)

      shot_group_fixture(%{count: 5}, current_user, first_pack)
      assert 125 = Ammo.get_round_count_for_container!(container, current_user)
    end

    test "get_round_count_for_containers/2 gets accurate total round count for containers",
         %{
           ammo_type: ammo_type,
           current_user: current_user,
           container: %{id: container_id} = container
         } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 5}, ammo_type, container, current_user)

      {1, [_first_pack]} = pack_fixture(%{count: 5}, ammo_type, another_container, current_user)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 5} = round_counts
      assert %{^another_container_id => 5} = round_counts

      {25, _packs} = pack_fixture(%{count: 5}, 25, ammo_type, container, current_user)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 130} = round_counts
      assert %{^another_container_id => 5} = round_counts

      shot_group_fixture(%{count: 5}, current_user, first_pack)

      round_counts =
        [container, another_container] |> Ammo.get_round_count_for_containers(current_user)

      assert %{^container_id => 125} = round_counts
      assert %{^another_container_id => 5} = round_counts
    end
  end

  describe "packs" do
    @valid_attrs %{
      count: 42,
      notes: "some notes",
      price_paid: 120.5,
      purchased_on: ~D[2022-11-19]
    }
    @update_attrs %{
      count: 43,
      notes: "some updated notes",
      price_paid: 456.7
    }
    @invalid_attrs %{
      count: nil,
      notes: nil,
      price_paid: nil
    }

    setup do
      current_user = user_fixture()
      ammo_type = ammo_type_fixture(current_user)
      container = container_fixture(current_user)

      {1, [pack]} =
        pack_fixture(%{count: 50, price_paid: 36.1}, ammo_type, container, current_user)

      another_user = user_fixture()
      another_ammo_type = ammo_type_fixture(another_user)
      another_container = container_fixture(another_user)

      {1, [_shouldnt_show_up]} = pack_fixture(another_ammo_type, another_container, another_user)

      [
        ammo_type: ammo_type,
        pack: pack,
        container: container,
        current_user: current_user
      ]
    end

    test "get_packs_count!/2 returns the correct amount of ammo",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      assert Ammo.get_packs_count!(current_user) == 1

      pack_fixture(ammo_type, container, current_user)
      assert Ammo.get_packs_count!(current_user) == 2

      pack_fixture(ammo_type, container, current_user)
      assert Ammo.get_packs_count!(current_user) == 3

      other_user = user_fixture()
      assert Ammo.get_packs_count!(other_user) == 0
      assert Ammo.get_packs_count!(other_user, true) == 0

      other_ammo_type = ammo_type_fixture(other_user)
      other_container = container_fixture(other_user)

      {1, [another_pack]} =
        pack_fixture(%{count: 30}, other_ammo_type, other_container, other_user)

      shot_group_fixture(%{count: 30}, other_user, another_pack)
      assert Ammo.get_packs_count!(other_user) == 0
      assert Ammo.get_packs_count!(other_user, true) == 1
    end

    test "list_packs/4 returns all packs for a type" do
      current_user = user_fixture()
      container = container_fixture(current_user)

      rifle_ammo_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_ammo_type, container, current_user)
      shotgun_ammo_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_ammo_type, container, current_user)
      pistol_ammo_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_ammo_type, container, current_user)

      assert [^rifle_pack] = Ammo.list_packs(nil, :rifle, current_user, false)
      assert [^shotgun_pack] = Ammo.list_packs(nil, :shotgun, current_user, false)
      assert [^pistol_pack] = Ammo.list_packs(nil, :pistol, current_user, false)

      packs = Ammo.list_packs(nil, :all, current_user, false)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs

      packs = Ammo.list_packs(nil, nil, current_user, false)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs
    end

    test "list_packs/4 returns all relevant packs including used", %{
      ammo_type: ammo_type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(%{count: 30}, ammo_type, container, current_user)

      shot_group_fixture(%{count: 30}, current_user, another_pack)
      another_pack = Ammo.get_pack!(another_pack_id, current_user)

      assert Ammo.list_packs(nil, :all, current_user, false) == [pack]

      packs = Ammo.list_packs(nil, :all, current_user, true)
      assert Enum.count(packs) == 2
      assert another_pack in packs
      assert pack in packs
    end

    test "list_packs/4 returns relevant ammo groups when searched", %{
      ammo_type: ammo_type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      {1, [another_pack]} =
        %{count: 49, notes: "cool ammo group"}
        |> pack_fixture(ammo_type, container, current_user)

      another_ammo_type = ammo_type_fixture(%{name: "amazing ammo"}, current_user)
      another_container = container_fixture(%{name: "fantastic container"}, current_user)

      tag = tag_fixture(%{name: "stupendous tag"}, current_user)
      Containers.add_tag!(another_container, tag, current_user)

      {1, [amazing_pack]} = pack_fixture(%{count: 48}, another_ammo_type, container, current_user)

      {1, [fantastic_pack]} =
        pack_fixture(%{count: 47}, ammo_type, another_container, current_user)

      packs = Ammo.list_packs(nil, :all, current_user, false)
      assert Enum.count(packs) == 4
      assert fantastic_pack in packs
      assert amazing_pack in packs
      assert another_pack in packs
      assert pack in packs

      # search works for ammo group attributes
      assert Ammo.list_packs("cool", :all, current_user, true) == [another_pack]

      # search works for ammo type attributes
      assert Ammo.list_packs("amazing", :all, current_user, true) == [amazing_pack]

      # search works for container attributes
      assert Ammo.list_packs("fantastic", :all, current_user, true) ==
               [fantastic_pack]

      # search works for container tag attributes
      assert Ammo.list_packs("stupendous", :all, current_user, true) ==
               [fantastic_pack]

      assert Ammo.list_packs("random", :all, current_user, true) == []
    end

    test "list_packs_for_type/3 returns all packs for a type", %{
      container: container,
      current_user: current_user
    } do
      ammo_type = ammo_type_fixture(current_user)
      {1, [pack]} = pack_fixture(ammo_type, container, current_user)
      assert [^pack] = Ammo.list_packs_for_type(ammo_type, current_user)

      shot_group_fixture(current_user, pack)
      pack = Ammo.get_pack!(pack.id, current_user)
      assert [] == Ammo.list_packs_for_type(ammo_type, current_user)
      assert [^pack] = Ammo.list_packs_for_type(ammo_type, current_user, true)
    end

    test "list_packs_for_container/3 returns all packs for a container" do
      current_user = user_fixture()
      container = container_fixture(current_user)

      rifle_ammo_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_ammo_type, container, current_user)
      shotgun_ammo_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_ammo_type, container, current_user)
      pistol_ammo_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_ammo_type, container, current_user)

      another_container = container_fixture(current_user)
      pack_fixture(rifle_ammo_type, another_container, current_user)
      pack_fixture(shotgun_ammo_type, another_container, current_user)
      pack_fixture(pistol_ammo_type, another_container, current_user)

      assert [^rifle_pack] = Ammo.list_packs_for_container(container, :rifle, current_user)

      assert [^shotgun_pack] = Ammo.list_packs_for_container(container, :shotgun, current_user)

      assert [^pistol_pack] = Ammo.list_packs_for_container(container, :pistol, current_user)

      packs = Ammo.list_packs_for_container(container, :all, current_user)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs

      packs = Ammo.list_packs_for_container(container, nil, current_user)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs
    end

    test "get_packs_count_for_type/2 returns count of packs for a type", %{
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert 1 = Ammo.get_packs_count_for_type(ammo_type, current_user)

      another_ammo_type = ammo_type_fixture(current_user)
      assert 0 = Ammo.get_packs_count_for_type(another_ammo_type, current_user)

      {5, _packs} = pack_fixture(%{}, 5, ammo_type, container, current_user)
      assert 6 = Ammo.get_packs_count_for_type(ammo_type, current_user)
    end

    test "get_packs_count_for_types/2 returns counts of packs for types", %{
      ammo_type: %{id: ammo_type_id} = ammo_type,
      container: container,
      current_user: current_user
    } do
      assert %{ammo_type_id => 1} ==
               [ammo_type] |> Ammo.get_packs_count_for_types(current_user)

      %{id: another_ammo_type_id} = another_ammo_type = ammo_type_fixture(current_user)

      assert %{ammo_type_id => 1} ==
               [ammo_type, another_ammo_type]
               |> Ammo.get_packs_count_for_types(current_user)

      {1, [_pack]} = pack_fixture(another_ammo_type, container, current_user)

      packs_count = [ammo_type, another_ammo_type] |> Ammo.get_packs_count_for_types(current_user)

      assert %{^ammo_type_id => 1} = packs_count
      assert %{^another_ammo_type_id => 1} = packs_count

      {5, _packs} = pack_fixture(%{}, 5, ammo_type, container, current_user)

      packs_count = [ammo_type, another_ammo_type] |> Ammo.get_packs_count_for_types(current_user)

      assert %{^ammo_type_id => 6} = packs_count
      assert %{^another_ammo_type_id => 1} = packs_count
    end

    test "list_staged_packs/1 returns all packs that are staged", %{
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [another_pack]} = pack_fixture(%{staged: true}, ammo_type, container, current_user)

      assert Ammo.list_staged_packs(current_user) == [another_pack]
    end

    test "get_pack!/2 returns the pack with given id",
         %{pack: %{id: pack_id} = pack, current_user: current_user} do
      assert Ammo.get_pack!(pack_id, current_user) == pack
    end

    test "get_packs/2 returns the packs with given id", %{
      pack: %{id: pack_id} = pack,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(ammo_type, container, current_user)

      packs = Ammo.get_packs([pack_id, another_pack_id], current_user)
      assert %{^pack_id => ^pack} = packs
      assert %{^another_pack_id => ^another_pack} = packs
    end

    test "create_packs/3 with valid data creates a pack", %{
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert {:ok, {1, [%Pack{} = pack]}} =
               @valid_attrs
               |> Map.merge(%{ammo_type_id: ammo_type.id, container_id: container.id})
               |> Ammo.create_packs(1, current_user)

      assert pack.count == 42
      assert pack.notes == "some notes"
      assert pack.price_paid == 120.5
    end

    test "create_packs/3 with valid data creates multiple packs", %{
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert {:ok, {3, packs}} =
               @valid_attrs
               |> Map.merge(%{ammo_type_id: ammo_type.id, container_id: container.id})
               |> Ammo.create_packs(3, current_user)

      assert [%Pack{}, %Pack{}, %Pack{}] = packs

      packs
      |> Enum.map(fn %{count: count, notes: notes, price_paid: price_paid} ->
        assert count == 42
        assert notes == "some notes"
        assert price_paid == 120.5
      end)
    end

    test "create_packs/3 with invalid data returns error changeset",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      assert {:error, %Changeset{}} =
               @invalid_attrs
               |> Map.merge(%{ammo_type_id: ammo_type.id, container_id: container.id})
               |> Ammo.create_packs(1, current_user)
    end

    test "update_pack/3 with valid data updates the pack",
         %{pack: pack, current_user: current_user} do
      assert {:ok, %Pack{} = pack} = Ammo.update_pack(pack, @update_attrs, current_user)

      assert pack.count == 43
      assert pack.notes == "some updated notes"
      assert pack.price_paid == 456.7
    end

    test "update_pack/3 with invalid data returns error changeset",
         %{pack: pack, current_user: current_user} do
      assert {:error, %Changeset{}} = Ammo.update_pack(pack, @invalid_attrs, current_user)

      assert pack == Ammo.get_pack!(pack.id, current_user)
    end

    test "delete_pack/2 deletes the pack",
         %{pack: pack, current_user: current_user} do
      assert {:ok, %Pack{}} = Ammo.delete_pack(pack, current_user)
      assert_raise KeyError, fn -> Ammo.get_pack!(pack.id, current_user) end
    end

    test "get_percentage_remaining/2 gets accurate total round count",
         %{pack: %{id: pack_id} = pack, current_user: current_user} do
      assert 100 = pack |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 72 = pack |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_percentage_remaining(current_user)

      shot_group_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 0 = pack |> Ammo.get_percentage_remaining(current_user)
    end

    test "get_percentages_remaining/2 gets accurate total round count", %{
      pack: %{id: pack_id} = pack,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      assert %{pack_id => 100} ==
               [pack] |> Ammo.get_percentages_remaining(current_user)

      {1, [%{id: another_pack_id} = another_pack]} =
        %{count: 50, price_paid: 36.1}
        |> pack_fixture(ammo_type, container, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 100} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_group_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 72} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_group_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 50} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_group_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 0} = percentages
      assert %{^another_pack_id => 100} = percentages
    end

    test "get_cpr/2 gets accurate cpr",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      {1, [pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)
      assert pack |> Ammo.get_cpr(current_user) |> is_nil()

      {1, [pack]} =
        pack_fixture(
          %{count: 1, price_paid: 1.0},
          ammo_type,
          container,
          current_user
        )

      assert 1.0 = pack |> Ammo.get_cpr(current_user)

      {1, [pack]} =
        pack_fixture(
          %{count: 2, price_paid: 3.0},
          ammo_type,
          container,
          current_user
        )

      assert 1.5 = pack |> Ammo.get_cpr(current_user)

      {1, [pack]} =
        pack_fixture(
          %{count: 50, price_paid: 36.1},
          ammo_type,
          container,
          current_user
        )

      assert 0.722 = pack |> Ammo.get_cpr(current_user)

      # with shot group, maintains total
      shot_group_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack.id, current_user)
      assert 0.722 = pack |> Ammo.get_cpr(current_user)
    end

    test "get_cprs/2 gets accurate cprs",
         %{ammo_type: ammo_type, container: container, current_user: current_user} do
      {1, [pack]} = pack_fixture(%{count: 1}, ammo_type, container, current_user)
      assert %{} == [pack] |> Ammo.get_cprs(current_user)

      {1, [%{id: pack_id} = pack]} =
        pack_fixture(
          %{count: 1, price_paid: 1.0},
          ammo_type,
          container,
          current_user
        )

      assert %{pack_id => 1.0} == [pack] |> Ammo.get_cprs(current_user)

      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(
          %{count: 2, price_paid: 3.0},
          ammo_type,
          container,
          current_user
        )

      cprs = [pack, another_pack] |> Ammo.get_cprs(current_user)
      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs

      {1, [%{id: yet_another_pack_id} = yet_another_pack]} =
        pack_fixture(
          %{count: 50, price_paid: 36.1},
          ammo_type,
          container,
          current_user
        )

      cprs = [pack, another_pack, yet_another_pack] |> Ammo.get_cprs(current_user)

      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs
      assert %{^yet_another_pack_id => 0.722} = cprs

      # with shot group, maintains total
      shot_group_fixture(%{count: 14}, current_user, yet_another_pack)
      yet_another_pack = Ammo.get_pack!(yet_another_pack.id, current_user)

      cprs = [pack, another_pack, yet_another_pack] |> Ammo.get_cprs(current_user)

      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs
      assert %{^yet_another_pack_id => 0.722} = cprs
    end

    test "get_original_count/2 gets accurate original count",
         %{pack: %{id: pack_id} = pack, current_user: current_user} do
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_group_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)
    end

    test "get_original_counts/2 gets accurate original counts", %{
      pack: %{id: pack_id} = pack,
      ammo_type: ammo_type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(%{count: 25}, ammo_type, container, current_user)

      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_group_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_group_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_group_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts
    end
  end
end
