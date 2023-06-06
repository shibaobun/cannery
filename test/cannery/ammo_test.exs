defmodule Cannery.AmmoTest do
  @moduledoc """
  Tests the Ammo context
  """

  use Cannery.DataCase, async: true
  alias Cannery.{Ammo, Ammo.Pack, Ammo.Type, Containers}
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

  describe "list_types/2" do
    setup do
      current_user = user_fixture()

      rifle_type =
        %{
          name: "bullets",
          class: :rifle,
          desc: "has some pews in it",
          grains: 53_453
        }
        |> type_fixture(current_user)

      shotgun_type =
        %{
          name: "hollows",
          class: :shotgun,
          grains: 3_234_234
        }
        |> type_fixture(current_user)

      pistol_type =
        %{
          class: :pistol,
          name: "jackets",
          desc: "brass shell",
          tracer: true
        }
        |> type_fixture(current_user)

      _shouldnt_return =
        %{
          name: "bullet",
          desc: "pews brass shell"
        }
        |> type_fixture(user_fixture())

      [
        rifle_type: rifle_type,
        shotgun_type: shotgun_type,
        pistol_type: pistol_type,
        current_user: current_user
      ]
    end

    test "list_types/2 returns all types", %{
      rifle_type: rifle_type,
      shotgun_type: shotgun_type,
      pistol_type: pistol_type,
      current_user: current_user
    } do
      results = Ammo.list_types(current_user, class: :all)
      assert results |> Enum.count() == 3
      assert rifle_type in results
      assert shotgun_type in results
      assert pistol_type in results
    end

    test "list_types/2 returns rifle types", %{
      rifle_type: rifle_type,
      current_user: current_user
    } do
      assert [^rifle_type] = Ammo.list_types(current_user, class: :rifle)
    end

    test "list_types/2 returns shotgun types", %{
      shotgun_type: shotgun_type,
      current_user: current_user
    } do
      assert [^shotgun_type] = Ammo.list_types(current_user, class: :shotgun)
    end

    test "list_types/2 returns pistol types", %{
      pistol_type: pistol_type,
      current_user: current_user
    } do
      assert [^pistol_type] = Ammo.list_types(current_user, class: :pistol)
    end

    test "list_types/2 returns relevant types for a user", %{
      rifle_type: rifle_type,
      shotgun_type: shotgun_type,
      pistol_type: pistol_type,
      current_user: current_user
    } do
      # name
      assert Ammo.list_types(current_user, search: "bullet") == [rifle_type]
      assert Ammo.list_types(current_user, search: "bullets") == [rifle_type]
      assert Ammo.list_types(current_user, search: "hollow") == [shotgun_type]
      assert Ammo.list_types(current_user, search: "jacket") == [pistol_type]

      # desc
      assert Ammo.list_types(current_user, search: "pew") == [rifle_type]
      assert Ammo.list_types(current_user, search: "brass") == [pistol_type]
      assert Ammo.list_types(current_user, search: "shell") == [pistol_type]

      # grains (integer)
      assert Ammo.list_types(current_user, search: "53453") == [rifle_type]
      assert Ammo.list_types(current_user, search: "3234234") == [shotgun_type]

      # tracer (boolean)
      assert Ammo.list_types(current_user, search: "tracer") == [pistol_type]
    end
  end

  describe "types" do
    setup do
      current_user = user_fixture()
      [type: type_fixture(current_user), current_user: current_user]
    end

    test "get_type!/2 returns the type with given id",
         %{type: type, current_user: current_user} do
      assert Ammo.get_type!(type.id, current_user) == type
    end

    test "get_types_count!/1 returns the correct amount of ammo",
         %{current_user: current_user} do
      assert Ammo.get_types_count!(current_user) == 1

      type_fixture(current_user)
      assert Ammo.get_types_count!(current_user) == 2

      type_fixture(current_user)
      assert Ammo.get_types_count!(current_user) == 3

      other_user = user_fixture()
      assert Ammo.get_types_count!(other_user) == 0

      type_fixture(other_user)
      assert Ammo.get_types_count!(other_user) == 1
    end

    test "create_type/2 with valid data creates a type",
         %{current_user: current_user} do
      assert {:ok, %Type{} = type} = Ammo.create_type(@valid_attrs, current_user)
      assert type.bullet_type == "some bullet_type"
      assert type.case_material == "some case_material"
      assert type.desc == "some desc"
      assert type.manufacturer == "some manufacturer"
      assert type.name == "some name"
      assert type.grains == 120
    end

    test "create_type/2 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Ammo.create_type(@invalid_attrs, current_user)
    end

    test "update_type/3 with valid data updates the type",
         %{type: type, current_user: current_user} do
      assert {:ok, %Type{} = type} = Ammo.update_type(type, @update_attrs, current_user)

      assert type.bullet_type == "some updated bullet_type"
      assert type.case_material == "some updated case_material"
      assert type.desc == "some updated desc"
      assert type.manufacturer == "some updated manufacturer"
      assert type.name == "some updated name"
      assert type.grains == 456
    end

    test "update_type/3 with invalid data returns error changeset",
         %{type: type, current_user: current_user} do
      assert {:error, %Changeset{}} = Ammo.update_type(type, @invalid_attrs, current_user)

      assert type == Ammo.get_type!(type.id, current_user)
    end

    test "delete_type/2 deletes the type",
         %{type: type, current_user: current_user} do
      assert {:ok, %Type{}} = Ammo.delete_type(type, current_user)
      assert_raise Ecto.NoResultsError, fn -> Ammo.get_type!(type.id, current_user) end
    end
  end

  describe "types with packs" do
    setup do
      current_user = user_fixture()
      type = type_fixture(current_user)
      container = container_fixture(current_user)

      [
        type: type,
        container: container,
        current_user: current_user
      ]
    end

    test "get_average_cost/2 gets average cost for type",
         %{type: type, current_user: current_user, container: container} do
      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost(type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          type,
          container,
          current_user
        )

      assert 25.0 = Ammo.get_average_cost(type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 70.00, count: 1},
          type,
          container,
          current_user
        )

      assert 40.0 = Ammo.get_average_cost(type, current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 30.00, count: 1},
          type,
          container,
          current_user
        )

      assert 37.5 = Ammo.get_average_cost(type, current_user)
    end

    test "get_average_costs/2 gets average costs for types", %{
      type: %{id: type_id} = type,
      current_user: current_user,
      container: container
    } do
      assert %{} == [type] |> Ammo.get_average_costs(current_user)

      %{id: another_type_id} = another_type = type_fixture(current_user)

      assert %{} ==
               [type, another_type]
               |> Ammo.get_average_costs(current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          another_type,
          container,
          current_user
        )

      assert %{another_type_id => 25.0} ==
               [type, another_type]
               |> Ammo.get_average_costs(current_user)

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          type,
          container,
          current_user
        )

      average_costs = [type, another_type] |> Ammo.get_average_costs(current_user)

      assert %{^type_id => 25.0} = average_costs
      assert %{^another_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 25.00, count: 1},
          type,
          container,
          current_user
        )

      average_costs = [type, another_type] |> Ammo.get_average_costs(current_user)

      assert %{^type_id => 25.0} = average_costs
      assert %{^another_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 70.00, count: 1},
          type,
          container,
          current_user
        )

      average_costs = [type, another_type] |> Ammo.get_average_costs(current_user)

      assert %{^type_id => 40.0} = average_costs
      assert %{^another_type_id => 25.0} = average_costs

      {1, [_pack]} =
        pack_fixture(
          %{price_paid: 30.00, count: 1},
          type,
          container,
          current_user
        )

      average_costs = [type, another_type] |> Ammo.get_average_costs(current_user)

      assert %{^type_id => 37.5} = average_costs
      assert %{^another_type_id => 25.0} = average_costs
    end

    test "get_round_count/2 gets accurate round count for type",
         %{type: type, current_user: current_user, container: container} do
      another_type = type_fixture(current_user)
      assert 0 = Ammo.get_round_count(current_user, type_id: another_type.id)

      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert 1 = Ammo.get_round_count(current_user, type_id: type.id)

      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)

      assert 51 = Ammo.get_round_count(current_user, type_id: type.id)

      shot_record_fixture(%{count: 26}, current_user, pack)
      assert 25 = Ammo.get_round_count(current_user, type_id: type.id)

      shot_record_fixture(%{count: 1}, current_user, first_pack)
      assert 24 = Ammo.get_round_count(current_user, type_id: type.id)
    end

    test "get_round_count_for_types/2 gets accurate round counts for types", %{
      type: %{id: type_id} = type,
      current_user: current_user,
      container: container
    } do
      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert %{type_id => 1} ==
               Ammo.get_grouped_round_count(current_user, types: [type], group_by: :type_id)

      %{id: another_type_id} = another_type = type_fixture(current_user)

      {1, [_another_pack]} = pack_fixture(%{count: 1}, another_type, container, current_user)

      round_counts =
        Ammo.get_grouped_round_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 1} = round_counts
      assert %{^another_type_id => 1} = round_counts

      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)

      round_counts =
        Ammo.get_grouped_round_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 51} = round_counts
      assert %{^another_type_id => 1} = round_counts

      shot_record_fixture(%{count: 26}, current_user, pack)

      round_counts =
        Ammo.get_grouped_round_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 25} = round_counts
      assert %{^another_type_id => 1} = round_counts

      shot_record_fixture(%{count: 1}, current_user, first_pack)

      round_counts =
        Ammo.get_grouped_round_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 24} = round_counts
      assert %{^another_type_id => 1} = round_counts
    end

    test "get_historical_count/2 gets accurate total round count for type",
         %{type: type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_historical_count(type, current_user)

      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert 1 = Ammo.get_historical_count(type, current_user)

      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)

      assert 51 = Ammo.get_historical_count(type, current_user)

      shot_record_fixture(%{count: 26}, current_user, pack)
      assert 51 = Ammo.get_historical_count(type, current_user)

      shot_record_fixture(%{count: 1}, current_user, first_pack)
      assert 51 = Ammo.get_historical_count(type, current_user)
    end

    test "get_historical_counts/2 gets accurate total round counts for types",
         %{
           type: %{id: type_id} = type,
           current_user: current_user,
           container: container
         } do
      assert %{} == [type] |> Ammo.get_historical_counts(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert %{type_id => 1} ==
               [type] |> Ammo.get_historical_counts(current_user)

      %{id: another_type_id} = another_type = type_fixture(current_user)

      {1, [_pack]} = pack_fixture(%{count: 1}, another_type, container, current_user)

      historical_counts = [type, another_type] |> Ammo.get_historical_counts(current_user)

      assert %{^type_id => 1} = historical_counts
      assert %{^another_type_id => 1} = historical_counts

      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)

      historical_counts = [type, another_type] |> Ammo.get_historical_counts(current_user)

      assert %{^type_id => 51} = historical_counts
      assert %{^another_type_id => 1} = historical_counts

      shot_record_fixture(%{count: 26}, current_user, pack)

      historical_counts = [type, another_type] |> Ammo.get_historical_counts(current_user)

      assert %{^type_id => 51} = historical_counts
      assert %{^another_type_id => 1} = historical_counts

      shot_record_fixture(%{count: 1}, current_user, first_pack)

      historical_counts = [type, another_type] |> Ammo.get_historical_counts(current_user)

      assert %{^type_id => 51} = historical_counts
      assert %{^another_type_id => 1} = historical_counts
    end

    test "get_packs_count/2 gets accurate total ammo count for type with show_used",
         %{type: type, current_user: current_user, container: container} do
      assert 0 = Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used)

      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert 0 = Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used)

      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)

      assert 0 = Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used)

      shot_record_fixture(%{count: 50}, current_user, pack)
      assert 1 = Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used)

      shot_record_fixture(%{count: 1}, current_user, first_pack)
      assert 2 = Ammo.get_packs_count(current_user, type_id: type.id, show_used: :only_used)
    end

    test "get_grouped_packs_count/2 gets accurate total ammo counts for types",
         %{
           type: %{id: type_id} = type,
           current_user: current_user,
           container: container
         } do
      # testing empty type
      assert %{} ==
               Ammo.get_grouped_packs_count(current_user,
                 types: [type],
                 group_by: :type_id,
                 show_used: :only_used
               )

      # testing two empty types
      %{id: another_type_id} = another_type = type_fixture(current_user)

      assert %{} ==
               Ammo.get_grouped_packs_count(current_user,
                 types: [type, another_type],
                 group_by: :type_id,
                 show_used: :only_used
               )

      # testing type with pack
      {1, [first_pack]} = pack_fixture(%{count: 1}, type, container, current_user)

      assert %{} ==
               Ammo.get_grouped_packs_count(current_user,
                 types: [type, another_type],
                 group_by: :type_id,
                 show_used: :only_used
               )

      # testing type with used pack
      {1, [another_pack]} = pack_fixture(%{count: 50}, another_type, container, current_user)

      shot_record_fixture(%{count: 50}, current_user, another_pack)

      assert %{another_type_id => 1} ==
               Ammo.get_grouped_packs_count(current_user,
                 types: [type, another_type],
                 group_by: :type_id,
                 show_used: :only_used
               )

      # testing two types with zero and one used packs
      {1, [pack]} = pack_fixture(%{count: 50}, type, container, current_user)
      shot_record_fixture(%{count: 50}, current_user, pack)

      used_counts =
        Ammo.get_grouped_packs_count(current_user,
          types: [type, another_type],
          group_by: :type_id,
          show_used: :only_used
        )

      assert %{^type_id => 1} = used_counts
      assert %{^another_type_id => 1} = used_counts

      # testing two type with one and two used packs
      shot_record_fixture(%{count: 1}, current_user, first_pack)

      used_counts =
        Ammo.get_grouped_packs_count(current_user,
          types: [type, another_type],
          group_by: :type_id,
          show_used: :only_used
        )

      assert %{^type_id => 2} = used_counts
      assert %{^another_type_id => 1} = used_counts
    end

    test "get_packs_count/2 gets accurate ammo count for container by container_id",
         %{type: type, current_user: current_user, container: container} do
      {1, [first_pack]} = pack_fixture(%{count: 5}, type, container, current_user)

      assert 1 = Ammo.get_packs_count(current_user, container_id: container.id)

      {25, _packs} = pack_fixture(%{count: 5}, 25, type, container, current_user)

      assert 26 = Ammo.get_packs_count(current_user, container_id: container.id)

      shot_record_fixture(%{count: 1}, current_user, first_pack)
      assert 26 = Ammo.get_packs_count(current_user, container_id: container.id)

      shot_record_fixture(%{count: 4}, current_user, first_pack)
      assert 25 = Ammo.get_packs_count(current_user, container_id: container.id)
    end

    test "get_grouped_packs_count/2 gets accurate ammo count for containers", %{
      type: type,
      current_user: current_user,
      container: %{id: container_id} = container
    } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 5}, type, container, current_user)

      {1, [_first_pack]} = pack_fixture(%{count: 5}, type, another_container, current_user)

      packs_count =
        Ammo.get_grouped_packs_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 1} = packs_count
      assert %{^another_container_id => 1} = packs_count

      {25, _packs} = pack_fixture(%{count: 5}, 25, type, container, current_user)

      packs_count =
        Ammo.get_grouped_packs_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 26} = packs_count
      assert %{^another_container_id => 1} = packs_count

      shot_record_fixture(%{count: 1}, current_user, first_pack)

      packs_count =
        Ammo.get_grouped_packs_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 26} = packs_count
      assert %{^another_container_id => 1} = packs_count

      shot_record_fixture(%{count: 4}, current_user, first_pack)

      packs_count =
        Ammo.get_grouped_packs_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 25} = packs_count
      assert %{^another_container_id => 1} = packs_count
    end

    test "get_round_count/2 gets accurate total round count for container_id",
         %{type: type, current_user: current_user, container: container} do
      {1, [first_pack]} = pack_fixture(%{count: 5}, type, container, current_user)

      assert 5 = Ammo.get_round_count(current_user, container_id: container.id)

      {25, _packs} = pack_fixture(%{count: 5}, 25, type, container, current_user)

      assert 130 = Ammo.get_round_count(current_user, container_id: container.id)

      shot_record_fixture(%{count: 5}, current_user, first_pack)
      assert 125 = Ammo.get_round_count(current_user, container_id: container.id)
    end

    test "get_grouped_round_count/2 gets accurate total round count for containers",
         %{
           type: type,
           current_user: current_user,
           container: %{id: container_id} = container
         } do
      %{id: another_container_id} = another_container = container_fixture(current_user)

      {1, [first_pack]} = pack_fixture(%{count: 5}, type, container, current_user)

      {1, [_first_pack]} = pack_fixture(%{count: 5}, type, another_container, current_user)

      round_counts =
        Ammo.get_grouped_round_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 5} = round_counts
      assert %{^another_container_id => 5} = round_counts

      {25, _packs} = pack_fixture(%{count: 5}, 25, type, container, current_user)

      round_counts =
        Ammo.get_grouped_round_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

      assert %{^container_id => 130} = round_counts
      assert %{^another_container_id => 5} = round_counts

      shot_record_fixture(%{count: 5}, current_user, first_pack)

      round_counts =
        Ammo.get_grouped_round_count(current_user,
          containers: [container, another_container],
          group_by: :container_id
        )

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
      type = type_fixture(current_user)
      container = container_fixture(current_user)

      {1, [pack]} = pack_fixture(%{count: 50, price_paid: 36.1}, type, container, current_user)

      another_user = user_fixture()
      another_type = type_fixture(another_user)
      another_container = container_fixture(another_user)

      {1, [_shouldnt_show_up]} = pack_fixture(another_type, another_container, another_user)

      [
        type: type,
        pack: pack,
        container: container,
        current_user: current_user
      ]
    end

    test "get_packs_count/2 returns the correct amount of ammo",
         %{type: type, container: container, current_user: current_user} do
      assert Ammo.get_packs_count(current_user) == 1

      pack_fixture(type, container, current_user)
      assert Ammo.get_packs_count(current_user) == 2

      pack_fixture(type, container, current_user)
      assert Ammo.get_packs_count(current_user) == 3

      other_user = user_fixture()
      assert Ammo.get_packs_count(other_user) == 0
      assert Ammo.get_packs_count(other_user, show_used: true) == 0

      other_type = type_fixture(other_user)
      other_container = container_fixture(other_user)

      {1, [another_pack]} = pack_fixture(%{count: 30}, other_type, other_container, other_user)

      shot_record_fixture(%{count: 30}, other_user, another_pack)
      assert Ammo.get_packs_count(other_user) == 0
      assert Ammo.get_packs_count(other_user, show_used: true) == 1
    end

    test "list_packs/2 returns all packs for a type" do
      current_user = user_fixture()
      container = container_fixture(current_user)

      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)

      assert [^rifle_pack] = Ammo.list_packs(current_user, class: :rifle)
      assert [^shotgun_pack] = Ammo.list_packs(current_user, class: :shotgun)
      assert [^pistol_pack] = Ammo.list_packs(current_user, class: :pistol)

      packs = Ammo.list_packs(current_user, class: :all)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs

      packs = Ammo.list_packs(current_user)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs
    end

    test "list_packs/2 returns all relevant packs including used", %{
      type: type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(%{count: 30}, type, container, current_user)

      shot_record_fixture(%{count: 30}, current_user, another_pack)
      another_pack = Ammo.get_pack!(another_pack_id, current_user)

      assert Ammo.list_packs(current_user, show_used: false) == [pack]

      packs = Ammo.list_packs(current_user, show_used: true)
      assert Enum.count(packs) == 2
      assert another_pack in packs
      assert pack in packs
    end

    test "list_packs/2 returns relevant packs when searched", %{
      type: type,
      pack: pack,
      container: container,
      current_user: current_user
    } do
      {1, [another_pack]} =
        %{count: 49, notes: "cool pack"}
        |> pack_fixture(type, container, current_user)

      another_type = type_fixture(%{name: "amazing ammo"}, current_user)
      another_container = container_fixture(%{name: "fantastic container"}, current_user)

      tag = tag_fixture(%{name: "stupendous tag"}, current_user)
      Containers.add_tag!(another_container, tag, current_user)

      {1, [amazing_pack]} = pack_fixture(%{count: 48}, another_type, container, current_user)

      {1, [fantastic_pack]} = pack_fixture(%{count: 47}, type, another_container, current_user)

      packs = Ammo.list_packs(current_user, search: nil)
      assert Enum.count(packs) == 4
      assert fantastic_pack in packs
      assert amazing_pack in packs
      assert another_pack in packs
      assert pack in packs

      # search works for pack attributes
      assert Ammo.list_packs(current_user, search: "cool") == [another_pack]

      # search works for type attributes
      assert Ammo.list_packs(current_user, search: "amazing") == [amazing_pack]

      # search works for container attributes
      assert Ammo.list_packs(current_user, search: "fantastic") == [fantastic_pack]

      # search works for container tag attributes
      assert Ammo.list_packs(current_user, search: "stupendous") == [fantastic_pack]
      assert Ammo.list_packs(current_user, search: "random") == []
    end

    test "list_packs/2 returns all relevant packs including staged", %{
      type: type,
      container: container,
      pack: unstaged_pack,
      current_user: current_user
    } do
      {1, [staged_pack]} = pack_fixture(%{staged: true}, type, container, current_user)

      assert Ammo.list_packs(current_user, staged: false) == [unstaged_pack]
      assert Ammo.list_packs(current_user, staged: true) == [staged_pack]

      packs = Ammo.list_packs(current_user)
      assert Enum.count(packs) == 2
      assert unstaged_pack in packs
      assert staged_pack in packs
    end

    test "list_packs/2 returns all relevant packs for a type", %{
      container: container,
      current_user: current_user
    } do
      type = type_fixture(current_user)
      {1, [pack]} = pack_fixture(type, container, current_user)
      assert [^pack] = Ammo.list_packs(current_user, type_id: type.id)

      shot_record_fixture(current_user, pack)
      pack = Ammo.get_pack!(pack.id, current_user)
      assert [] == Ammo.list_packs(current_user, type_id: type.id)
      assert [^pack] = Ammo.list_packs(current_user, type_id: type.id, show_used: true)
    end

    test "list_packs/2 returns all relevant packs for a container" do
      current_user = user_fixture()
      container = container_fixture(current_user)

      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)

      another_container = container_fixture(current_user)
      pack_fixture(rifle_type, another_container, current_user)
      pack_fixture(shotgun_type, another_container, current_user)
      pack_fixture(pistol_type, another_container, current_user)

      assert [^rifle_pack] =
               Ammo.list_packs(current_user, container_id: container.id, class: :rifle)

      assert [^shotgun_pack] =
               Ammo.list_packs(current_user, container_id: container.id, class: :shotgun)

      assert [^pistol_pack] =
               Ammo.list_packs(current_user, container_id: container.id, class: :pistol)

      packs = Ammo.list_packs(current_user, container_id: container.id, class: :all)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs

      packs = Ammo.list_packs(current_user, container_id: container.id)
      assert Enum.count(packs) == 3
      assert rifle_pack in packs
      assert shotgun_pack in packs
      assert pistol_pack in packs
    end

    test "get_packs_count/2 with type_id returns count of packs for a type", %{
      type: type,
      container: container,
      current_user: current_user
    } do
      assert 1 = Ammo.get_packs_count(current_user, type_id: type.id)

      another_type = type_fixture(current_user)
      assert 0 = Ammo.get_packs_count(current_user, type_id: another_type.id)

      {5, _packs} = pack_fixture(%{}, 5, type, container, current_user)
      assert 6 = Ammo.get_packs_count(current_user, type_id: type.id)
    end

    test "get_grouped_packs_count/2 returns counts of packs for types", %{
      type: %{id: type_id} = type,
      container: container,
      current_user: current_user
    } do
      assert %{type_id => 1} ==
               Ammo.get_grouped_packs_count(current_user, types: [type], group_by: :type_id)

      %{id: another_type_id} = another_type = type_fixture(current_user)

      assert %{type_id => 1} ==
               Ammo.get_grouped_packs_count(current_user,
                 types: [type, another_type],
                 group_by: :type_id
               )

      {1, [_pack]} = pack_fixture(another_type, container, current_user)

      packs_count =
        Ammo.get_grouped_packs_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 1} = packs_count
      assert %{^another_type_id => 1} = packs_count

      {5, _packs} = pack_fixture(%{}, 5, type, container, current_user)

      packs_count =
        Ammo.get_grouped_packs_count(current_user, types: [type, another_type], group_by: :type_id)

      assert %{^type_id => 6} = packs_count
      assert %{^another_type_id => 1} = packs_count
    end

    test "get_pack!/2 returns the pack with given id",
         %{pack: %{id: pack_id} = pack, current_user: current_user} do
      assert Ammo.get_pack!(pack_id, current_user) == pack
    end

    test "get_packs/2 returns the packs with given id", %{
      pack: %{id: pack_id} = pack,
      type: type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} = pack_fixture(type, container, current_user)

      packs = Ammo.get_packs([pack_id, another_pack_id], current_user)
      assert %{^pack_id => ^pack} = packs
      assert %{^another_pack_id => ^another_pack} = packs
    end

    test "create_packs/3 with valid data creates a pack", %{
      type: type,
      container: container,
      current_user: current_user
    } do
      assert {:ok, {1, [%Pack{} = pack]}} =
               @valid_attrs
               |> Map.merge(%{type_id: type.id, container_id: container.id})
               |> Ammo.create_packs(1, current_user)

      assert pack.count == 42
      assert pack.notes == "some notes"
      assert pack.price_paid == 120.5
    end

    test "create_packs/3 with valid data creates multiple packs", %{
      type: type,
      container: container,
      current_user: current_user
    } do
      assert {:ok, {3, packs}} =
               @valid_attrs
               |> Map.merge(%{type_id: type.id, container_id: container.id})
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
         %{type: type, container: container, current_user: current_user} do
      assert {:error, %Changeset{}} =
               @invalid_attrs
               |> Map.merge(%{type_id: type.id, container_id: container.id})
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

      shot_record_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 72 = pack |> Ammo.get_percentage_remaining(current_user)

      shot_record_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_percentage_remaining(current_user)

      shot_record_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 0 = pack |> Ammo.get_percentage_remaining(current_user)
    end

    test "get_percentages_remaining/2 gets accurate total round count", %{
      pack: %{id: pack_id} = pack,
      type: type,
      container: container,
      current_user: current_user
    } do
      assert %{pack_id => 100} ==
               [pack] |> Ammo.get_percentages_remaining(current_user)

      {1, [%{id: another_pack_id} = another_pack]} =
        %{count: 50, price_paid: 36.1}
        |> pack_fixture(type, container, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 100} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_record_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 72} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_record_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 50} = percentages
      assert %{^another_pack_id => 100} = percentages

      shot_record_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)

      percentages = [pack, another_pack] |> Ammo.get_percentages_remaining(current_user)

      assert %{^pack_id => 0} = percentages
      assert %{^another_pack_id => 100} = percentages
    end

    test "get_cpr/2 gets accurate cpr",
         %{type: type, container: container, current_user: current_user} do
      {1, [pack]} = pack_fixture(%{count: 1}, type, container, current_user)
      assert pack |> Ammo.get_cpr(current_user) |> is_nil()

      {1, [pack]} =
        pack_fixture(
          %{count: 1, price_paid: 1.0},
          type,
          container,
          current_user
        )

      assert 1.0 = pack |> Ammo.get_cpr(current_user)

      {1, [pack]} =
        pack_fixture(
          %{count: 2, price_paid: 3.0},
          type,
          container,
          current_user
        )

      assert 1.5 = pack |> Ammo.get_cpr(current_user)

      {1, [pack]} =
        pack_fixture(
          %{count: 50, price_paid: 36.1},
          type,
          container,
          current_user
        )

      assert 0.722 = pack |> Ammo.get_cpr(current_user)

      # with shot record, maintains total
      shot_record_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack.id, current_user)
      assert 0.722 = pack |> Ammo.get_cpr(current_user)
    end

    test "get_cprs/2 gets accurate cprs",
         %{type: type, container: container, current_user: current_user} do
      {1, [pack]} = pack_fixture(%{count: 1}, type, container, current_user)
      assert %{} == [pack] |> Ammo.get_cprs(current_user)

      {1, [%{id: pack_id} = pack]} =
        pack_fixture(
          %{count: 1, price_paid: 1.0},
          type,
          container,
          current_user
        )

      assert %{pack_id => 1.0} == [pack] |> Ammo.get_cprs(current_user)

      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(
          %{count: 2, price_paid: 3.0},
          type,
          container,
          current_user
        )

      cprs = [pack, another_pack] |> Ammo.get_cprs(current_user)
      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs

      {1, [%{id: yet_another_pack_id} = yet_another_pack]} =
        pack_fixture(
          %{count: 50, price_paid: 36.1},
          type,
          container,
          current_user
        )

      cprs = [pack, another_pack, yet_another_pack] |> Ammo.get_cprs(current_user)

      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs
      assert %{^yet_another_pack_id => 0.722} = cprs

      # with shot record, maintains total
      shot_record_fixture(%{count: 14}, current_user, yet_another_pack)
      yet_another_pack = Ammo.get_pack!(yet_another_pack.id, current_user)

      cprs = [pack, another_pack, yet_another_pack] |> Ammo.get_cprs(current_user)

      assert %{^pack_id => 1.0} = cprs
      assert %{^another_pack_id => 1.5} = cprs
      assert %{^yet_another_pack_id => 0.722} = cprs
    end

    test "get_original_count/2 gets accurate original count",
         %{pack: %{id: pack_id} = pack, current_user: current_user} do
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_record_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_record_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)

      shot_record_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      assert 50 = pack |> Ammo.get_original_count(current_user)
    end

    test "get_original_counts/2 gets accurate original counts", %{
      pack: %{id: pack_id} = pack,
      type: type,
      container: container,
      current_user: current_user
    } do
      {1, [%{id: another_pack_id} = another_pack]} =
        pack_fixture(%{count: 25}, type, container, current_user)

      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_record_fixture(%{count: 14}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_record_fixture(%{count: 11}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts

      shot_record_fixture(%{count: 25}, current_user, pack)
      pack = Ammo.get_pack!(pack_id, current_user)
      original_counts = [pack, another_pack] |> Ammo.get_original_counts(current_user)
      assert %{^pack_id => 50} = original_counts
      assert %{^another_pack_id => 25} = original_counts
    end
  end
end
