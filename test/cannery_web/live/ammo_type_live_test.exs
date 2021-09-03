defmodule CanneryWeb.AmmoTypeLiveTest do
  use CanneryWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Cannery.Ammo

  @create_attrs %{bullet_type: "some bullet_type", case_material: "some case_material", desc: "some desc", manufacturer: "some manufacturer", name: "some name", weight: 120.5}
  @update_attrs %{bullet_type: "some updated bullet_type", case_material: "some updated case_material", desc: "some updated desc", manufacturer: "some updated manufacturer", name: "some updated name", weight: 456.7}
  @invalid_attrs %{bullet_type: nil, case_material: nil, desc: nil, manufacturer: nil, name: nil, weight: nil}

  defp fixture(:ammo_type) do
    {:ok, ammo_type} = Ammo.create_ammo_type(@create_attrs)
    ammo_type
  end

  defp create_ammo_type(_) do
    ammo_type = fixture(:ammo_type)
    %{ammo_type: ammo_type}
  end

  describe "Index" do
    setup [:create_ammo_type]

    test "lists all ammo_types", %{conn: conn, ammo_type: ammo_type} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ "Listing Ammo types"
      assert html =~ ammo_type.bullet_type
    end

    test "saves new ammo_type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("a", "New Ammo type") |> render_click() =~
               "New Ammo type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :new))

      assert index_live
             |> form("#ammo_type-form", ammo_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ammo_type-form", ammo_type: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ "Ammo type created successfully"
      assert html =~ "some bullet_type"
    end

    test "updates ammo_type in listing", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("#ammo_type-#{ammo_type.id} a", "Edit") |> render_click() =~
               "Edit Ammo type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :edit, ammo_type))

      assert index_live
             |> form("#ammo_type-form", ammo_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ammo_type-form", ammo_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ "Ammo type updated successfully"
      assert html =~ "some updated bullet_type"
    end

    test "deletes ammo_type in listing", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("#ammo_type-#{ammo_type.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#ammo_type-#{ammo_type.id}")
    end
  end

  describe "Show" do
    setup [:create_ammo_type]

    test "displays ammo_type", %{conn: conn, ammo_type: ammo_type} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ "Show Ammo type"
      assert html =~ ammo_type.bullet_type
    end

    test "updates ammo_type within modal", %{conn: conn, ammo_type: ammo_type} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Ammo type"

      assert_patch(show_live, Routes.ammo_type_show_path(conn, :edit, ammo_type))

      assert show_live
             |> form("#ammo_type-form", ammo_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#ammo_type-form", ammo_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ "Ammo type updated successfully"
      assert html =~ "some updated bullet_type"
    end
  end
end
