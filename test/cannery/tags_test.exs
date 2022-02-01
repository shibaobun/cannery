defmodule Cannery.TagsTest do
  use Cannery.DataCase

  alias Cannery.{AccountsFixtures, Tags}
  alias Ecto.Changeset

  describe "tags" do
    alias Cannery.Tags.Tag

    @valid_attrs %{
      "bg_color" => "some bg-color",
      "name" => "some name",
      "text_color" => "some text-color"
    }
    @update_attrs %{
      "bg_color" => "some updated bg-color",
      "name" => "some updated name",
      "text_color" => "some updated text-color"
    }
    @invalid_attrs %{
      "bg_color" => nil,
      "name" => nil,
      "text_color" => nil
    }

    def tag_fixture(attrs \\ %{}) do
      %{id: user_id} = AccountsFixtures.user_fixture()

      {:ok, tag} =
        attrs
        |> Map.put("user_id", user_id)
        |> Enum.into(@valid_attrs)
        |> Tags.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Tags.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Tags.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Tags.create_tag(@valid_attrs)
      assert tag.bg_color == "some bg-color"
      assert tag.name == "some name"
      assert tag.text_color == "some text-color"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Changeset{}} = Tags.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = Tags.update_tag(tag, @update_attrs)
      assert tag.bg_color == "some updated bg-color"
      assert tag.name == "some updated name"
      assert tag.text_color == "some updated text-color"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Changeset{}} = Tags.update_tag(tag, @invalid_attrs)
      assert tag == Tags.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Tags.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Changeset{} = Tags.change_tag(tag)
    end
  end
end
