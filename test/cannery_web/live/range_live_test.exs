defmodule CanneryWeb.RangeLiveTest do
  @moduledoc """
  This module tests the Range LiveViews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import Cannery.Fixtures
  import CanneryWeb.Gettext

  @moduletag :range_live_test
  @create_attrs %{"ammo_left" => 5, "notes" => "some notes"}
  @update_attrs %{"count" => 16, "notes" => "some updated notes"}
  # @invalid_attrs %{"count" => nil, "notes" => nil}

  defp create_shot_group(%{current_user: current_user}) do
    container = container_fixture(%{"staged" => true}, current_user)
    ammo_type = ammo_type_fixture(current_user)

    {1, [ammo_group]} =
      ammo_group_fixture(%{"staged" => true}, ammo_type, container, current_user)

    shot_group =
      %{"count" => 5, "date" => ~N[2022-02-13 03:17:00], "notes" => "some notes"}
      |> shot_group_fixture(current_user, ammo_group)

    %{shot_group: shot_group, ammo_group: ammo_group}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_shot_group]

    test "lists all shot_groups", %{conn: conn, shot_group: shot_group} do
      {:ok, _index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ gettext("Range day")
      assert html =~ shot_group.notes
    end

    test "can search for shot_group", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ shot_group.notes

      assert index_live
             |> form("[data-qa=\"shot_group_search\"]",
               search: %{search_term: shot_group.notes}
             )
             |> render_change() =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, shot_group.notes))

      refute index_live
             |> form("[data-qa=\"shot_group_search\"]", search: %{search_term: "something_else"})
             |> render_change() =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, "something_else"))

      assert index_live
             |> form("[data-qa=\"shot_group_search\"]", search: %{search_term: ""})
             |> render_change() =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :index))
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Record shots")) |> render_click() =~
               gettext("Record shots")

      assert_patch(index_live, Routes.range_index_path(conn, :add_shot_group, ammo_group))

      # assert index_live
      #        |> form("#shot_group-form", shot_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "is invalid")

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Shots recorded successfully")
      assert html =~ "some notes"
    end

    test "updates shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"edit-#{shot_group.id}\"]") |> render_click() =~
               gettext("Edit Shot Records")

      assert_patch(index_live, Routes.range_index_path(conn, :edit, shot_group))

      # assert index_live
      #        |> form("#shot_group-form", shot_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "is invalid")

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ dgettext("actions", "Shot records updated successfully")
      assert html =~ "some updated notes"
    end

    test "deletes shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{shot_group.id}\"]") |> render_click()
      refute has_element?(index_live, "#shot_group-#{shot_group.id}")
    end
  end
end
