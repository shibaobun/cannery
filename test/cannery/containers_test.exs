defmodule Cannery.ContainersTest do
  @moduledoc """
  Tests for the Containers context
  """

  use Cannery.DataCase
  alias Cannery.Containers
  alias Cannery.{Accounts.User, Containers.Container}
  alias Ecto.Changeset

  @moduletag :containers_test

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
  @invalid_attrs %{"desc" => nil, "location" => nil, "name" => nil, "type" => nil}

  describe "containers" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      [current_user: current_user, container: container]
    end

    test "list_containers/1 returns all containers",
         %{current_user: current_user, container: container} do
      assert Containers.list_containers(current_user) == [container]
    end

    test "get_container!/1 returns the container with given id",
         %{current_user: current_user, container: container} do
      assert Containers.get_container!(container.id, current_user) == container
    end

    test "create_container/1 with valid data creates a container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{} = container} =
               @valid_attrs |> Containers.create_container(current_user)

      assert container.desc == "some desc"
      assert container.location == "some location"
      assert container.name == "some name"
      assert container.type == "some type"
      assert container.user_id == current_user.id
    end

    test "create_container/1 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = @invalid_attrs |> Containers.create_container(current_user)
    end

    test "update_container/2 with valid data updates the container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{} = container} =
               Containers.update_container(container, current_user, @update_attrs)

      assert container.desc == "some updated desc"
      assert container.location == "some updated location"
      assert container.name == "some updated name"
      assert container.type == "some updated type"
    end

    test "update_container/2 with invalid data returns error changeset",
         %{current_user: current_user, container: container} do
      assert {:error, %Changeset{}} =
               Containers.update_container(container, current_user, @invalid_attrs)

      assert container == Containers.get_container!(container.id, current_user)
    end

    test "delete_container/1 deletes the container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{}} = Containers.delete_container(container, current_user)

      assert_raise Ecto.NoResultsError, fn ->
        Containers.get_container!(container.id, current_user)
      end
    end

    test "change_container/1 returns a container changeset", %{container: container} do
      assert %Changeset{} = Containers.change_container(container)
    end
  end
end
