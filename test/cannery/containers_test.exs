defmodule Cannery.ContainersTest do
  @moduledoc """
  Tests for the Containers context
  """

  use Cannery.DataCase
  alias Cannery.Containers
  alias Cannery.{Containers.Container}
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
  @invalid_attrs %{
    "desc" => nil,
    "location" => nil,
    "name" => nil,
    "type" => nil
  }

  describe "containers" do
    setup do
      current_user = user_fixture()
      container = container_fixture(current_user)
      [current_user: current_user, container: container]
    end

    test "list_containers/1 returns all containers",
         %{current_user: current_user, container: container} do
      assert Containers.list_containers(current_user) ==
               [container] |> preload_containers()
    end

    test "list_containers/2 returns relevant containers for a user",
         %{current_user: current_user} do
      container_a =
        container_fixture(%{"name" => "my cool container"}, current_user) |> preload_containers()

      container_b =
        container_fixture(%{"desc" => "a fascinating description"}, current_user)
        |> preload_containers()

      container_c = container_fixture(%{"location" => "a secret place"}, current_user)
      tag = tag_fixture(%{"name" => "stupendous tag"}, current_user)
      Containers.add_tag!(container_c, tag, current_user)
      container_c = container_c |> preload_containers()

      container_d = container_fixture(%{"type" => "musty old box"}, current_user)
      tag = tag_fixture(%{"name" => "amazing tag"}, current_user)
      Containers.add_tag!(container_d, tag, current_user)
      container_d = container_d |> preload_containers()

      _shouldnt_return =
        container_fixture(%{"name" => "another person's container"}, user_fixture())

      # attributes
      assert Containers.list_containers("cool", current_user) == [container_a]
      assert Containers.list_containers("fascinating", current_user) == [container_b]
      assert Containers.list_containers("secret", current_user) == [container_c]
      assert Containers.list_containers("box", current_user) == [container_d]

      # tags
      assert Containers.list_containers("stupendous", current_user) == [container_c]
      assert Containers.list_containers("amazing", current_user) == [container_d]

      assert Containers.list_containers("asajslkdflskdf", current_user) == []
    end

    defp preload_containers(containers),
      do: containers |> Repo.preload([:ammo_groups, :tags])

    test "get_container!/1 returns the container with given id",
         %{current_user: current_user, container: container} do
      assert Containers.get_container!(container.id, current_user) ==
               container |> Repo.preload([:ammo_groups, :tags])
    end

    test "create_container/1 with valid data creates a container", %{current_user: current_user} do
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

      assert container |> Repo.preload([:ammo_groups, :tags]) ==
               Containers.get_container!(container.id, current_user)
    end

    test "delete_container/1 deletes the container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{}} = Containers.delete_container(container, current_user)

      assert_raise Ecto.NoResultsError, fn ->
        Containers.get_container!(container.id, current_user)
      end
    end
  end
end
