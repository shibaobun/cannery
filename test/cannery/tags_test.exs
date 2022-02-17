defmodule Cannery.TagsTest do
  @moduledoc """
  Tests the Tags context
  """

  use Cannery.DataCase
  alias Cannery.{Tags, Tags.Tag}
  alias Ecto.Changeset

  @moduletag :tags_test

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

  describe "tags" do
    setup do
      current_user = user_fixture()
      [tag: tag_fixture(current_user), current_user: current_user]
    end

    test "list_tags/0 returns all tags", %{tag: tag, current_user: current_user} do
      assert Tags.list_tags(current_user) == [tag]
    end

    test "get_tag!/1 returns the tag with given id", %{tag: tag, current_user: current_user} do
      assert Tags.get_tag!(tag.id, current_user) == tag
    end

    test "create_tag/1 with valid data creates a tag", %{tag: tag, current_user: current_user} do
      assert {:ok, %Tag{} = tag} = Tags.create_tag(@valid_attrs, current_user)
      assert tag.bg_color == "some bg-color"
      assert tag.name == "some name"
      assert tag.text_color == "some text-color"
    end

    test "create_tag/1 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Tags.create_tag(@invalid_attrs, current_user)
    end

    test "update_tag/2 with valid data updates the tag", %{tag: tag, current_user: current_user} do
      assert {:ok, %Tag{} = tag} = Tags.update_tag(tag, @update_attrs, current_user)
      assert tag.bg_color == "some updated bg-color"
      assert tag.name == "some updated name"
      assert tag.text_color == "some updated text-color"
    end

    test "update_tag/2 with invalid data returns error changeset",
         %{tag: tag, current_user: current_user} do
      assert {:error, %Changeset{}} = Tags.update_tag(tag, @invalid_attrs, current_user)
      assert tag == Tags.get_tag!(tag.id, current_user)
    end

    test "delete_tag/1 deletes the tag", %{tag: tag, current_user: current_user} do
      assert {:ok, %Tag{}} = Tags.delete_tag(tag, current_user)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(tag.id, current_user) end
    end

    test "change_tag/1 returns a tag changeset", %{tag: tag} do
      assert %Changeset{} = Tags.change_tag(tag)
    end
  end
end
