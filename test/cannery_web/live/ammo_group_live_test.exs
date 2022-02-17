defmodule CanneryWeb.AmmoGroupLiveTest do
  @moduledoc """
  Tests ammo group live pages
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.Repo

  @moduletag :ammo_group_live_test
  @create_attrs %{count: 42, notes: "some notes", price_paid: 120.5}
  @update_attrs %{count: 43, notes: "some updated notes", price_paid: 456.7}
  @invalid_attrs %{count: -1, notes: nil, price_paid: nil}

  defp create_ammo_group(%{current_user: current_user}) do
    ammo_type = ammo_type_fixture(current_user)
    container = container_fixture(current_user)
    %{ammo_group: ammo_group_fixture(ammo_type, container, current_user)}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "lists all ammo_groups", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ gettext("Ammo groups")
      assert html =~ ammo_group.ammo_type.name
    end

    test "saves new ammo_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "New Ammo group")) |> render_click() =~
               gettext("New Ammo group")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo group created successfully")
      assert html =~ "some notes"
    end

    test "updates ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element("[data-qa=\"edit-#{ammo_group.id}\"]")
             |> render_click() =~
               gettext("Edit Ammo group")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :edit, ammo_group))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo group updated successfully")
      assert html =~ "some updated notes"
    end

    test "deletes ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element("[data-qa=\"delete-#{ammo_group.id}\"]")
             |> render_click()

      refute has_element?(index_live, "#ammo_group-#{ammo_group.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "displays ammo_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ gettext("Show Ammo group")
      assert html =~ ammo_group.ammo_type.name
    end

    test "updates ammo_group within modal", %{conn: conn, ammo_group: ammo_group} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert show_live
             |> element("[data-qa=\"edit\"]")
             |> render_click() =~
               gettext("Edit Ammo group")

      assert_patch(show_live, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      # assert show_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        show_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ dgettext("prompts", "Ammo group updated successfully")
      assert html =~ "some updated notes"
    end
  end
end
