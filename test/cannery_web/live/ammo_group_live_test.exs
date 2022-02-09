defmodule CanneryWeb.AmmoGroupLiveTest do
  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.Ammo

  @create_attrs %{count: 42, notes: "some notes", price_paid: 120.5}
  @update_attrs %{count: 43, notes: "some updated notes", price_paid: 456.7}
  @invalid_attrs %{count: nil, notes: nil, price_paid: nil}

  defp fixture(:ammo_group) do
    {:ok, ammo_group} = Ammo.create_ammo_group(@create_attrs)
    ammo_group
  end

  defp create_ammo_group(_) do
    ammo_group = fixture(:ammo_group)
    %{ammo_group: ammo_group}
  end

  describe "Index" do
    setup [:create_ammo_group]

    test "lists all ammo_groups", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Listing Ammo groups"
      assert html =~ ammo_group.notes
    end

    test "saves new ammo_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", "New Ammo group") |> render_click() =~
               "New Ammo group"

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      assert index_live
             |> form("#ammo_group-form", ammo_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo group created successfully"
      assert html =~ "some notes"
    end

    test "updates ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("#ammo_group-#{ammo_group.id} a", "Edit") |> render_click() =~
               "Edit Ammo group"

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :edit, ammo_group))

      assert index_live
             |> form("#ammo_group-form", ammo_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo group updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("#ammo_group-#{ammo_group.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#ammo_group-#{ammo_group.id}")
    end
  end

  describe "Show" do
    setup [:create_ammo_group]

    test "displays ammo_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ "Show Ammo group"
      assert html =~ ammo_group.notes
    end

    test "updates ammo_group within modal", %{conn: conn, ammo_group: ammo_group} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Ammo group"

      assert_patch(show_live, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      assert show_live
             |> form("#ammo_group-form", ammo_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ "Ammo group updated successfully"
      assert html =~ "some updated notes"
    end
  end
end
