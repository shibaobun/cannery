defmodule CanneryWeb.TagLiveTest do
  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.Tags

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

  defp fixture(:tag) do
    {:ok, tag} = Tags.create_tag(@create_attrs)
    tag
  end

  defp create_tag(_) do
    tag = fixture(:tag)
    %{tag: tag}
  end

  describe "Index" do
    setup [:create_tag]

    test "lists all tags", %{conn: conn, tag: tag} do
      {:ok, _index_live, html} = live(conn, Routes.tag_index_path(conn, :index))

      assert html =~ "Listing Tags"
      assert html =~ tag.bg_color
    end

    test "saves new tag", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("a", "New Tag") |> render_click() =~
               "New Tag"

      assert_patch(index_live, Routes.tag_index_path(conn, :new))

      assert index_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#tag-form", tag: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tag_index_path(conn, :index))

      assert html =~ "Tag created successfully"
      assert html =~ "some bg-color"
    end

    test "updates tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("#tag-#{tag.id} a", "Edit") |> render_click() =~
               "Edit Tag"

      assert_patch(index_live, Routes.tag_index_path(conn, :edit, tag))

      assert index_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#tag-form", tag: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tag_index_path(conn, :index))

      assert html =~ "Tag updated successfully"
      assert html =~ "some updated bg-color"
    end

    test "deletes tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, Routes.tag_index_path(conn, :index))

      assert index_live |> element("#tag-#{tag.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tag-#{tag.id}")
    end
  end

  describe "Show" do
    setup [:create_tag]

    test "displays tag", %{conn: conn, tag: tag} do
      {:ok, _show_live, html} = live(conn, Routes.tag_show_path(conn, :show, tag))

      assert html =~ "Show Tag"
      assert html =~ tag.bg_color
    end

    test "updates tag within modal", %{conn: conn, tag: tag} do
      {:ok, show_live, _html} = live(conn, Routes.tag_show_path(conn, :show, tag))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tag"

      assert_patch(show_live, Routes.tag_show_path(conn, :edit, tag))

      assert show_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#tag-form", tag: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tag_show_path(conn, :show, tag))

      assert html =~ "Tag updated successfully"
      assert html =~ "some updated bg-color"
    end
  end
end
