defmodule CanneryWeb.TagLiveTest do
  @moduledoc """
  Tests the tag liveviews
  """

  use CanneryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @moduletag :tag_live_test

  @create_attrs %{
    bg_color: "#100000",
    name: "some name",
    text_color: "#000000"
  }
  @update_attrs %{
    bg_color: "#100001",
    name: "some updated name",
    text_color: "#000001"
  }
  @invalid_attrs %{
    bg_color: nil,
    name: nil,
    text_color: nil
  }

  def create_tag(%{current_user: current_user}) do
    tag = tag_fixture(current_user)
    %{tag: tag, current_user: current_user}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_tag]

    test "lists all tags", %{conn: conn, tag: tag} do
      {:ok, _index_live, html} = live(conn, ~p"/tags")

      assert html =~ "Tags"
      assert html =~ tag.bg_color
    end

    test "can search for tag", %{conn: conn, tag: tag} do
      {:ok, index_live, html} = live(conn, ~p"/tags")

      assert html =~ tag.name

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: tag.name}) =~ tag.name

      assert_patch(index_live, ~p"/tags/search/#{tag.name}")

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ tag.name

      assert_patch(index_live, ~p"/tags/search/something_else")

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ tag.name

      assert_patch(index_live, ~p"/tags")
    end

    test "saves new tag", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tags")

      assert index_live |> element("a", "New Tag") |> render_click() =~ "New Tag"
      assert_patch(index_live, ~p"/tags/new")

      assert index_live
             |> form("#tag-form")
             |> render_change(tag: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#tag-form")
        |> render_submit(tag: @create_attrs)
        |> follow_redirect(conn, ~p"/tags")

      assert html =~ "some name created successfully"
      assert html =~ "#100000"
    end

    test "updates tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, ~p"/tags")

      assert index_live |> element(~s/a[aria-label="Edit #{tag.name}"]/) |> render_click() =~
               "Edit Tag"

      assert_patch(index_live, ~p"/tags/edit/#{tag}")

      assert index_live
             |> form("#tag-form")
             |> render_change(tag: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#tag-form")
        |> render_submit(tag: @update_attrs)
        |> follow_redirect(conn, ~p"/tags")

      assert html =~ "some updated name updated successfully"
      assert html =~ "#100001"
    end

    test "deletes tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, ~p"/tags")

      assert index_live |> element(~s/a[aria-label="Delete #{tag.name}"]/) |> render_click()
      refute has_element?(index_live, "#tag-#{tag.id}")
    end
  end
end
