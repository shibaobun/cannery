defmodule Cannery.ContainersTest do
  use Cannery.DataCase

  alias Cannery.Containers

  describe "containers" do
    alias Cannery.Containers.Container

    @valid_attrs %{
      "desc" => "some desc",
      "location" => "some location",
      "name" => "some name",
      "type" => "some type"
    }
    @update_attrs %{
      "desc" => "some updated desc",
      "location" => "some updated location",
      "name" => "some updated name",
      "type" => "some updated type"
    }
    @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}

    def container_fixture(attrs \\ %{}) do
      {:ok, container} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Containers.create_container()

      container
    end

    test "list_containers/0 returns all containers" do
      container = container_fixture()
      assert Containers.list_containers() == [container]
    end

    test "get_container!/1 returns the container with given id" do
      container = container_fixture()
      assert Containers.get_container!(container.id) == container
    end

    test "create_container/1 with valid data creates a container" do
      assert {:ok, %Container{} = container} = Containers.create_container(@valid_attrs)
      assert container.desc == "some desc"
      assert container.location == "some location"
      assert container.name == "some name"
      assert container.type == "some type"
    end

    test "create_container/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Containers.create_container(@invalid_attrs)
    end

    test "update_container/2 with valid data updates the container" do
      container = container_fixture()

      assert {:ok, %Container{} = container} =
               Containers.update_container(container, @update_attrs)

      assert container.desc == "some updated desc"
      assert container.location == "some updated location"
      assert container.name == "some updated name"
      assert container.type == "some updated type"
    end

    test "update_container/2 with invalid data returns error changeset" do
      container = container_fixture()
      assert {:error, %Ecto.Changeset{}} = Containers.update_container(container, @invalid_attrs)
      assert container == Containers.get_container!(container.id)
    end

    test "delete_container/1 deletes the container" do
      container = container_fixture()
      assert {:ok, %Container{}} = Containers.delete_container(container)
      assert_raise Ecto.NoResultsError, fn -> Containers.get_container!(container.id) end
    end

    test "change_container/1 returns a container changeset" do
      container = container_fixture()
      assert %Ecto.Changeset{} = Containers.change_container(container)
    end
  end
end
