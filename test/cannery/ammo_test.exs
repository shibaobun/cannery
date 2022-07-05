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

    test "list_ammo_types/0 returns all ammo_types",
         %{ammo_type: ammo_type, current_user: current_user} do
      assert Ammo.list_ammo_types(current_user) == [ammo_type]
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

  describe "ammo_groups" do
    @valid_attrs %{"count" => 42, "notes" => "some notes", "price_paid" => 120.5}
    @update_attrs %{"count" => 43, "notes" => "some updated notes", "price_paid" => 456.7}
    @invalid_attrs %{"count" => nil, "notes" => nil, "price_paid" => nil}

    setup do
      current_user = user_fixture()
      ammo_type = ammo_type_fixture(current_user)
      container = container_fixture(current_user)
      {1, [ammo_group]} = ammo_group_fixture(ammo_type, container, current_user)

      [
        ammo_type: ammo_type,
        ammo_group: ammo_group,
        container: container,
        current_user: current_user
      ]
    end

    test "list_ammo_groups/0 returns all ammo_groups",
         %{ammo_group: ammo_group, current_user: current_user} do
      assert Ammo.list_ammo_groups(current_user) == [ammo_group] |> Repo.preload(:shot_groups)
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
  end
end
