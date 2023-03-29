defmodule CanneryWeb.RangeLiveTest do
  @moduledoc """
  This module tests the Range LiveViews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import Cannery.Fixtures

  @moduletag :range_live_test
  @create_attrs %{ammo_left: 5, notes: "some notes"}
  @update_attrs %{count: 16, notes: "some updated notes"}
  @invalid_attrs %{count: nil, notes: nil}

  defp create_shot_group(%{current_user: current_user}) do
    container = container_fixture(%{staged: true}, current_user)
    ammo_type = ammo_type_fixture(current_user)

    {1, [ammo_group]} = ammo_group_fixture(%{staged: true}, ammo_type, container, current_user)

    shot_group =
      %{count: 5, date: ~N[2022-02-13 03:17:00], notes: "some notes"}
      |> shot_group_fixture(current_user, ammo_group)

    [
      container: container,
      ammo_type: ammo_type,
      ammo_group: ammo_group,
      shot_group: shot_group
    ]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_shot_group]

    test "lists all shot_groups", %{conn: conn, shot_group: shot_group} do
      {:ok, _index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Range day"
      assert html =~ shot_group.notes
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_ammo_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_ammo_group]} = ammo_group_fixture(rifle_ammo_type, container, current_user)

      rifle_shot_group = shot_group_fixture(%{notes: "group_one"}, current_user, rifle_ammo_group)

      shotgun_ammo_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_ammo_group]} = ammo_group_fixture(shotgun_ammo_type, container, current_user)

      shotgun_shot_group =
        shot_group_fixture(%{notes: "group_two"}, current_user, shotgun_ammo_group)

      pistol_ammo_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_ammo_group]} = ammo_group_fixture(pistol_ammo_type, container, current_user)

      pistol_shot_group =
        shot_group_fixture(%{notes: "group_three"}, current_user, pistol_ammo_group)

      {:ok, index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ "All"

      assert html =~ rifle_shot_group.notes
      assert html =~ shotgun_shot_group.notes
      assert html =~ pistol_shot_group.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :rifle})

      assert html =~ rifle_shot_group.notes
      refute html =~ shotgun_shot_group.notes
      refute html =~ pistol_shot_group.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :shotgun})

      refute html =~ rifle_shot_group.notes
      assert html =~ shotgun_shot_group.notes
      refute html =~ pistol_shot_group.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :pistol})

      refute html =~ rifle_shot_group.notes
      refute html =~ shotgun_shot_group.notes
      assert html =~ pistol_shot_group.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :all})

      assert html =~ rifle_shot_group.notes
      assert html =~ shotgun_shot_group.notes
      assert html =~ pistol_shot_group.notes
    end

    test "can search for shot_group", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ shot_group.notes

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: shot_group.notes}) =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, shot_group.notes))

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ shot_group.notes

      assert_patch(index_live, Routes.range_index_path(conn, :index))
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.range_index_path(conn, :add_shot_group, ammo_group))

      assert index_live
             |> form("#shot-group-form")
             |> render_change(shot_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form")
        |> render_submit(shot_group: @create_attrs)
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Shots recorded successfully"
      assert html =~ "some notes"
    end

    test "updates shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Edit shot record of #{shot_group.count} shots"]/)
             |> render_click() =~ "Edit Shot Records"

      assert_patch(index_live, Routes.range_index_path(conn, :edit, shot_group))

      assert index_live
             |> form("#shot-group-form")
             |> render_change(shot_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Shot records updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes shot_group in listing", %{conn: conn, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Delete shot record of #{shot_group.count} shots"]/)
             |> render_click()

      refute has_element?(index_live, "#shot_group-#{shot_group.id}")
    end
  end
end
