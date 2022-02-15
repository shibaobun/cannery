defmodule CanneryWeb.ShotGroupLiveTest do
  use CanneryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Cannery.ActivityLogFixtures

  @create_attrs %{
    count: 42,
    date: %{day: 13, hour: 3, minute: 17, month: 2, year: 2022},
    notes: "some notes"
  }
  @update_attrs %{
    count: 43,
    date: %{day: 14, hour: 3, minute: 17, month: 2, year: 2022},
    notes: "some updated notes"
  }
  @invalid_attrs %{
    count: nil,
    date: %{day: 30, hour: 3, minute: 17, month: 2, year: 2022},
    notes: nil
  }

  defp create_shot_group(_) do
    shot_group = shot_group_fixture()
    %{shot_group: shot_group}
  end

  describe "Index" do
    setup [:create_shot_group]

    test "lists all shot_groups", %{conn: conn, shot_group: shot_group} do
      {:ok, _index_live, html} = live(conn, Routes.shot_group_index_path(conn, :index))

      assert html =~ "Shot records"
      assert html =~ shot_group.notes
    end

    test "saves new shot_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.shot_group_index_path(conn, :index))

      assert index_live |> element("a", "New Shot group") |> render_click() =~
               "New Shot group"

      assert_patch(index_live, Routes.shot_group_index_path(conn, :new))

      assert index_live
             |> form("#shot_group-form", shot_group: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        index_live
        |> form("#shot_group-form", shot_group: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.shot_group_index_path(conn, :index))

      assert html =~ "Shot group created successfully"
      assert html =~ "some notes"
    end

    test "updates shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.shot_group_index_path(conn, :index))

      assert index_live |> element("#shot_group-#{shot_group.id} a", "Edit") |> render_click() =~
               "Edit Shot group"

      assert_patch(index_live, Routes.shot_group_index_path(conn, :edit, shot_group))

      assert index_live
             |> form("#shot_group-form", shot_group: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        index_live
        |> form("#shot_group-form", shot_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.shot_group_index_path(conn, :index))

      assert html =~ "Shot group updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.shot_group_index_path(conn, :index))

      assert index_live |> element("#shot_group-#{shot_group.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#shot_group-#{shot_group.id}")
    end
  end

  describe "Show" do
    setup [:create_shot_group]

    test "displays shot_group", %{conn: conn, shot_group: shot_group} do
      {:ok, _show_live, html} = live(conn, Routes.shot_group_show_path(conn, :show, shot_group))

      assert html =~ "Show Shot group"
      assert html =~ shot_group.notes
    end

    test "updates shot_group within modal", %{conn: conn, shot_group: shot_group} do
      {:ok, show_live, _html} = live(conn, Routes.shot_group_show_path(conn, :show, shot_group))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Shot group"

      assert_patch(show_live, Routes.shot_group_show_path(conn, :edit, shot_group))

      assert show_live
             |> form("#shot_group-form", shot_group: @invalid_attrs)
             |> render_change() =~ "is invalid"

      {:ok, _, html} =
        show_live
        |> form("#shot_group-form", shot_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.shot_group_show_path(conn, :show, shot_group))

      assert html =~ "Shot group updated successfully"
      assert html =~ "some updated notes"
    end
  end
end
