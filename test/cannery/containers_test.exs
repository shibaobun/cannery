defmodule Cannery.ContainersTest do
  @moduledoc """
  Tests for the Containers context
  """

  use Cannery.DataCase

  alias Cannery.Containers
  alias Cannery.{Accounts.User, Containers.Container}
  alias Ecto.Changeset

  @moduletag :containers

  describe "containers" do
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

    @spec container_fixture(User.t(), map()) :: Container.t()
    def container_fixture(user, attrs \\ %{}) do
      {:ok, container} = @valid_attrs |> Map.merge(attrs) |> Containers.create_container(user)

      container
    end

    test "list_containers/1 returns all containers" do
      user = user_fixture()
      container = user |> container_fixture()
      assert Containers.list_containers(user) == [container]
    end

    test "get_container!/1 returns the container with given id" do
      container = user_fixture() |> container_fixture()
      assert Containers.get_container!(container.id) == container
    end

    test "create_container/1 with valid data creates a container" do
      user = user_fixture()
      assert {:ok, %Container{} = container} = @valid_attrs |> Containers.create_container(user)
      assert container.desc == "some desc"
      assert container.location == "some location"
      assert container.name == "some name"
      assert container.type == "some type"
      assert container.user_id == user.id
    end

    test "create_container/1 with invalid data returns error changeset" do
      assert {:error, %Changeset{}} =
               @invalid_attrs |> Containers.create_container(user_fixture())
    end

    test "update_container/2 with valid data updates the container" do
      user = user_fixture()
      container = user |> container_fixture()

      assert {:ok, %Container{} = container} =
               Containers.update_container(container, user, @update_attrs)

      assert container.desc == "some updated desc"
      assert container.location == "some updated location"
      assert container.name == "some updated name"
      assert container.type == "some updated type"
    end

    test "update_container/2 with invalid data returns error changeset" do
      user = user_fixture()
      container = user |> container_fixture()
      assert {:error, %Changeset{}} = Containers.update_container(container, user, @invalid_attrs)
      assert container == Containers.get_container!(container.id)
    end

    test "delete_container/1 deletes the container" do
      user = user_fixture()
      container = user |> container_fixture()
      assert {:ok, %Container{}} = Containers.delete_container(container, user)
      assert_raise Ecto.NoResultsError, fn -> Containers.get_container!(container.id) end
    end

    test "change_container/1 returns a container changeset" do
      container = user_fixture() |> container_fixture()
      assert %Changeset{} = Containers.change_container(container)
    end
  end
end
