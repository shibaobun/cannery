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

  defp create_shot_record(%{current_user: current_user}) do
    container = container_fixture(%{staged: true}, current_user)
    ammo_type = ammo_type_fixture(current_user)

    {1, [pack]} = pack_fixture(%{staged: true}, ammo_type, container, current_user)

    shot_record =
      %{count: 5, date: ~N[2022-02-13 03:17:00], notes: "some notes"}
      |> shot_record_fixture(current_user, pack)

    [
      container: container,
      ammo_type: ammo_type,
      pack: pack,
      shot_record: shot_record
    ]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_shot_record]

    test "lists all shot_records", %{conn: conn, shot_record: shot_record} do
      {:ok, _index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Range day"
      assert html =~ shot_record.notes
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_ammo_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_ammo_type, container, current_user)

      rifle_shot_record = shot_record_fixture(%{notes: "group_one"}, current_user, rifle_pack)

      shotgun_ammo_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_ammo_type, container, current_user)

      shotgun_shot_record = shot_record_fixture(%{notes: "group_two"}, current_user, shotgun_pack)

      pistol_ammo_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_ammo_type, container, current_user)

      pistol_shot_record = shot_record_fixture(%{notes: "group_three"}, current_user, pistol_pack)

      {:ok, index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ "All"

      assert html =~ rifle_shot_record.notes
      assert html =~ shotgun_shot_record.notes
      assert html =~ pistol_shot_record.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :rifle})

      assert html =~ rifle_shot_record.notes
      refute html =~ shotgun_shot_record.notes
      refute html =~ pistol_shot_record.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :shotgun})

      refute html =~ rifle_shot_record.notes
      assert html =~ shotgun_shot_record.notes
      refute html =~ pistol_shot_record.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :pistol})

      refute html =~ rifle_shot_record.notes
      refute html =~ shotgun_shot_record.notes
      assert html =~ pistol_shot_record.notes

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :all})

      assert html =~ rifle_shot_record.notes
      assert html =~ shotgun_shot_record.notes
      assert html =~ pistol_shot_record.notes
    end

    test "can search for shot_record", %{conn: conn, shot_record: shot_record} do
      {:ok, index_live, html} = live(conn, Routes.range_index_path(conn, :index))

      assert html =~ shot_record.notes

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: shot_record.notes}) =~ shot_record.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, shot_record.notes))

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ shot_record.notes

      assert_patch(index_live, Routes.range_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ shot_record.notes

      assert_patch(index_live, Routes.range_index_path(conn, :index))
    end

    test "saves new shot_record", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.range_index_path(conn, :add_shot_record, pack))

      assert index_live
             |> form("#shot-record-form")
             |> render_change(shot_record: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-record-form")
        |> render_submit(shot_record: @create_attrs)
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Shots recorded successfully"
      assert html =~ "some notes"
    end

    test "updates shot_record in listing", %{conn: conn, shot_record: shot_record} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Edit shot record of #{shot_record.count} shots"]/)
             |> render_click() =~ "Edit Shot Record"

      assert_patch(index_live, Routes.range_index_path(conn, :edit, shot_record))

      assert index_live
             |> form("#shot-record-form")
             |> render_change(shot_record: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-record-form", shot_record: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.range_index_path(conn, :index))

      assert html =~ "Shot records updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes shot_record in listing", %{conn: conn, shot_record: shot_record} do
      {:ok, index_live, _html} = live(conn, Routes.range_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Delete shot record of #{shot_record.count} shots"]/)
             |> render_click()

      refute has_element?(index_live, "#shot_record-#{shot_record.id}")
    end
  end
end
