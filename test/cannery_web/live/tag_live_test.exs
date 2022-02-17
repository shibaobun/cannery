defmodule CanneryWeb.TagLiveTest do
  @moduledoc """
  Tests the tag liveviews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext

  @moduletag :tag_live_test

  @create_attrs %{
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

  def create_tag %{current_user: current_user} do
    tag = tag_fixture(current_user)
    %{tag: tag, current_user: current_user}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_tag]

    test "lists all tags", %{conn: conn, tag: tag} do
      {:ok, _index_live, html} = live(conn, Routes.tag_index_path(conn, :index))

      assert html =~ gettext("Tags")
      assert html =~ tag.bg_color
    end

    test "saves new tag", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "New Tag")) |> render_click() =~
               dgettext("actions", "New Tag")

      assert_patch(index_live, Routes.tag_index_path(conn, :new))

      # assert index_live
      #        |> form("#tag-form", tag: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#tag-form", tag: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tag_index_path(conn, :index))

      assert html =~ dgettext("actions", "%{name} created successfully", name: "some name")
      assert html =~ "some bg-color"
    end

    test "updates tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"edit-#{tag.id}\"]") |> render_click() =~
               dgettext("actions", "Edit Tag")

      assert_patch(index_live, Routes.tag_index_path(conn, :edit, tag))

      # assert index_live
      #        |> form("#tag-form", tag: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#tag-form", tag: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tag_index_path(conn, :index))

      assert html =~ dgettext("prompts", "%{name} updated successfully", name: "some updated name")
      assert html =~ "some updated bg-color"
    end

    test "deletes tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{tag.id}\"]") |> render_click()
      refute has_element?(index_live, "#tag-#{tag.id}")
    end
  end
end
