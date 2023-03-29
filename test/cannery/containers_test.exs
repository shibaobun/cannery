defmodule Cannery.ContainersTest do
  @moduledoc """
  Tests for the Containers context
  """

  use Cannery.DataCase
  alias Cannery.{Containers, Containers.Container, Containers.Tag}
  alias Ecto.Changeset

  @moduletag :containers_test

  @valid_attrs %{
    desc: "some desc",
    location: "some location",
    name: "some name",
    type: "some type"
  }
  @update_attrs %{
    desc: "some updated desc",
    location: "some updated location",
    name: "some updated name",
    type: "some updated type"
  }
  @invalid_attrs %{
    desc: nil,
    location: nil,
    name: nil,
    type: nil
  }
  @valid_tag_attrs %{
    bg_color: "#100000",
    name: "some name",
    text_color: "#000000"
  }
  @update_tag_attrs %{
    bg_color: "#100001",
    name: "some updated name",
    text_color: "#000001"
  }
  @invalid_tag_attrs %{
    bg_color: nil,
    name: nil,
    text_color: nil
  }

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

    test "list_containers/2 returns relevant containers for a user",
         %{current_user: current_user} do
      container_a = container_fixture(%{name: "my cool container"}, current_user)
      container_b = container_fixture(%{desc: "a fascinating description"}, current_user)

      %{id: container_c_id} =
        container_c = container_fixture(%{location: "a secret place"}, current_user)

      tag = tag_fixture(%{name: "stupendous tag"}, current_user)
      Containers.add_tag!(container_c, tag, current_user)
      container_c = container_c_id |> Containers.get_container!(current_user)

      %{id: container_d_id} =
        container_d = container_fixture(%{type: "musty old box"}, current_user)

      tag = tag_fixture(%{name: "amazing tag"}, current_user)
      Containers.add_tag!(container_d, tag, current_user)
      container_d = container_d_id |> Containers.get_container!(current_user)

      _shouldnt_return = container_fixture(%{name: "another person's container"}, user_fixture())

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

    test "get_container!/2 returns the container with given id",
         %{current_user: current_user, container: container} do
      assert Containers.get_container!(container.id, current_user) == container
      assert_raise KeyError, fn -> Containers.get_container!(current_user.id, current_user) end
    end

    test "get_containers/2 returns the container with given id",
         %{current_user: current_user, container: %{id: container_id} = container} do
      assert %{container_id => container} ==
               Containers.get_containers([container_id], current_user)

      %{id: another_container_id} = another_container = container_fixture(current_user)
      containers = [container_id, another_container_id] |> Containers.get_containers(current_user)
      assert %{^container_id => ^container} = containers
      assert %{^another_container_id => ^another_container} = containers
    end

    test "create_container/2 with valid data creates a container", %{current_user: current_user} do
      assert {:ok, %Container{} = container} =
               Containers.create_container(@valid_attrs, current_user)

      assert container.desc == "some desc"
      assert container.location == "some location"
      assert container.name == "some name"
      assert container.type == "some type"
      assert container.user_id == current_user.id
    end

    test "create_container/2 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Containers.create_container(@invalid_attrs, current_user)
    end

    test "update_container/3 with valid data updates the container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{} = container} =
               Containers.update_container(container, current_user, @update_attrs)

      assert container.desc == "some updated desc"
      assert container.location == "some updated location"
      assert container.name == "some updated name"
      assert container.type == "some updated type"
    end

    test "update_container/3 with invalid data returns error changeset",
         %{current_user: current_user, container: container} do
      assert {:error, %Changeset{}} =
               Containers.update_container(container, current_user, @invalid_attrs)

      assert container == Containers.get_container!(container.id, current_user)
    end

    test "delete_container/2 deletes the container",
         %{current_user: current_user, container: container} do
      assert {:ok, %Container{}} = Containers.delete_container(container, current_user)

      assert_raise KeyError, fn ->
        Containers.get_container!(container.id, current_user)
      end
    end
  end

  describe "tags" do
    setup do
      current_user = user_fixture()
      [tag: tag_fixture(current_user), current_user: current_user]
    end

    test "list_tags/1 returns all tags", %{tag: tag, current_user: current_user} do
      assert Containers.list_tags(current_user) == [tag]
    end

    test "list_tags/2 returns relevant tags for a user", %{current_user: current_user} do
      tag_a = tag_fixture(%{name: "bullets"}, current_user)
      tag_b = tag_fixture(%{name: "hollows"}, current_user)

      tag_fixture(%{name: "bullet", desc: "pews brass shell"}, user_fixture())

      # name
      assert Containers.list_tags("bullet", current_user) == [tag_a]
      assert Containers.list_tags("bullets", current_user) == [tag_a]
      assert Containers.list_tags("hollow", current_user) == [tag_b]
      assert Containers.list_tags("hollows", current_user) == [tag_b]
    end

    test "get_tag!/2 returns the tag with given id", %{tag: tag, current_user: current_user} do
      assert Containers.get_tag!(tag.id, current_user) == tag
    end

    test "create_tag/2 with valid data creates a tag", %{current_user: current_user} do
      assert {:ok, %Tag{} = tag} = Containers.create_tag(@valid_tag_attrs, current_user)
      assert tag.bg_color == "#100000"
      assert tag.name == "some name"
      assert tag.text_color == "#000000"
    end

    test "create_tag/2 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Containers.create_tag(@invalid_tag_attrs, current_user)
    end

    test "update_tag/3 with valid data updates the tag", %{tag: tag, current_user: current_user} do
      assert {:ok, %Tag{} = tag} = Containers.update_tag(tag, @update_tag_attrs, current_user)
      assert tag.bg_color == "#100001"
      assert tag.name == "some updated name"
      assert tag.text_color == "#000001"
    end

    test "update_tag/3 with invalid data returns error changeset",
         %{tag: tag, current_user: current_user} do
      assert {:error, %Changeset{}} = Containers.update_tag(tag, @invalid_tag_attrs, current_user)
      assert tag == Containers.get_tag!(tag.id, current_user)
    end

    test "delete_tag/2 deletes the tag", %{tag: tag, current_user: current_user} do
      assert {:ok, %Tag{}} = Containers.delete_tag(tag, current_user)
      assert_raise Ecto.NoResultsError, fn -> Containers.get_tag!(tag.id, current_user) end
    end
  end
end
