defmodule Cannery.AmmoTest do
  use Cannery.DataCase

  alias Cannery.Ammo

  describe "ammo_types" do
    alias Cannery.Ammo.AmmoType

    @valid_attrs %{
      "bullet_type" => "some bullet_type",
      "case_material" => "some case_material",
      "desc" => "some desc",
      "manufacturer" => "some manufacturer",
      "name" => "some name",
      "weight" => 120.5
    }
    @update_attrs %{
      "bullet_type" => "some updated bullet_type",
      "case_material" => "some updated case_material",
      "desc" => "some updated desc",
      "manufacturer" => "some updated manufacturer",
      "name" => "some updated name",
      "weight" => 456.7
    }
    @invalid_attrs %{
      "bullet_type" => nil,
      "case_material" => nil,
      "desc" => nil,
      "manufacturer" => nil,
      "name" => nil,
      "weight" => nil
    }

    def ammo_type_fixture(attrs \\ %{}) do
      {:ok, ammo_type} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ammo.create_ammo_type()

      ammo_type
    end

    test "list_ammo_types/0 returns all ammo_types" do
      ammo_type = ammo_type_fixture()
      assert Ammo.list_ammo_types() == [ammo_type]
    end

    test "get_ammo_type!/1 returns the ammo_type with given id" do
      ammo_type = ammo_type_fixture()
      assert Ammo.get_ammo_type!(ammo_type.id) == ammo_type
    end

    test "create_ammo_type/1 with valid data creates a ammo_type" do
      assert {:ok, %AmmoType{} = ammo_type} = Ammo.create_ammo_type(@valid_attrs)
      assert ammo_type.bullet_type == "some bullet_type"
      assert ammo_type.case_material == "some case_material"
      assert ammo_type.desc == "some desc"
      assert ammo_type.manufacturer == "some manufacturer"
      assert ammo_type.name == "some name"
      assert ammo_type.weight == 120.5
    end

    test "create_ammo_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ammo.create_ammo_type(@invalid_attrs)
    end

    test "update_ammo_type/2 with valid data updates the ammo_type" do
      ammo_type = ammo_type_fixture()
      assert {:ok, %AmmoType{} = ammo_type} = Ammo.update_ammo_type(ammo_type, @update_attrs)
      assert ammo_type.bullet_type == "some updated bullet_type"
      assert ammo_type.case_material == "some updated case_material"
      assert ammo_type.desc == "some updated desc"
      assert ammo_type.manufacturer == "some updated manufacturer"
      assert ammo_type.name == "some updated name"
      assert ammo_type.weight == 456.7
    end

    test "update_ammo_type/2 with invalid data returns error changeset" do
      ammo_type = ammo_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Ammo.update_ammo_type(ammo_type, @invalid_attrs)
      assert ammo_type == Ammo.get_ammo_type!(ammo_type.id)
    end

    test "delete_ammo_type/1 deletes the ammo_type" do
      ammo_type = ammo_type_fixture()
      assert {:ok, %AmmoType{}} = Ammo.delete_ammo_type(ammo_type)
      assert_raise Ecto.NoResultsError, fn -> Ammo.get_ammo_type!(ammo_type.id) end
    end

    test "change_ammo_type/1 returns a ammo_type changeset" do
      ammo_type = ammo_type_fixture()
      assert %Ecto.Changeset{} = Ammo.change_ammo_type(ammo_type)
    end
  end

  describe "ammo_groups" do
    alias Cannery.Ammo.AmmoGroup

    @valid_attrs %{count: 42, notes: "some notes", price_paid: 120.5}
    @update_attrs %{count: 43, notes: "some updated notes", price_paid: 456.7}
    @invalid_attrs %{count: nil, notes: nil, price_paid: nil}

    def ammo_group_fixture(attrs \\ %{}) do
      {:ok, ammo_group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ammo.create_ammo_group()

      ammo_group
    end

    test "list_ammo_groups/0 returns all ammo_groups" do
      ammo_group = ammo_group_fixture()
      assert Ammo.list_ammo_groups() == [ammo_group]
    end

    test "get_ammo_group!/1 returns the ammo_group with given id" do
      ammo_group = ammo_group_fixture()
      assert Ammo.get_ammo_group!(ammo_group.id) == ammo_group
    end

    test "create_ammo_group/1 with valid data creates a ammo_group" do
      assert {:ok, %AmmoGroup{} = ammo_group} = Ammo.create_ammo_group(@valid_attrs)
      assert ammo_group.count == 42
      assert ammo_group.notes == "some notes"
      assert ammo_group.price_paid == 120.5
    end

    test "create_ammo_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ammo.create_ammo_group(@invalid_attrs)
    end

    test "update_ammo_group/2 with valid data updates the ammo_group" do
      ammo_group = ammo_group_fixture()
      assert {:ok, %AmmoGroup{} = ammo_group} = Ammo.update_ammo_group(ammo_group, @update_attrs)
      assert ammo_group.count == 43
      assert ammo_group.notes == "some updated notes"
      assert ammo_group.price_paid == 456.7
    end

    test "update_ammo_group/2 with invalid data returns error changeset" do
      ammo_group = ammo_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Ammo.update_ammo_group(ammo_group, @invalid_attrs)
      assert ammo_group == Ammo.get_ammo_group!(ammo_group.id)
    end

    test "delete_ammo_group/1 deletes the ammo_group" do
      ammo_group = ammo_group_fixture()
      assert {:ok, %AmmoGroup{}} = Ammo.delete_ammo_group(ammo_group)
      assert_raise Ecto.NoResultsError, fn -> Ammo.get_ammo_group!(ammo_group.id) end
    end

    test "change_ammo_group/1 returns a ammo_group changeset" do
      ammo_group = ammo_group_fixture()
      assert %Ecto.Changeset{} = Ammo.change_ammo_group(ammo_group)
    end
  end
end
