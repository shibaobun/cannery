defmodule CanneryWeb.AmmoTypeLiveTest do
  @moduledoc """
  Tests the ammo type liveview
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.Ammo

  @moduletag :ammo_type_live_test

  @create_attrs %{
    "bullet_type" => "some bullet_type",
    "case_material" => "some case_material",
    "desc" => "some desc",
    "manufacturer" => "some manufacturer",
    "name" => "some name",
    "grains" => 120
  }
  @update_attrs %{
    "bullet_type" => "some updated bullet_type",
    "case_material" => "some updated case_material",
    "desc" => "some updated desc",
    "manufacturer" => "some updated manufacturer",
    "name" => "some updated name",
    "grains" => 456
  }

  # @invalid_attrs %{
  #   "bullet_type" => nil,
  #   "case_material" => nil,
  #   "desc" => nil,
  #   "manufacturer" => nil,
  #   "name" => nil,
  #   "grains" => nil
  # }

  defp create_ammo_type(%{current_user: current_user}) do
    %{ammo_type: ammo_type_fixture(@create_attrs, current_user)}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_ammo_type]

    test "lists all ammo_types", %{conn: conn, ammo_type: ammo_type} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ gettext("Ammo types")
      assert html =~ ammo_type.bullet_type
    end

    test "saves new ammo_type", %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "New Ammo type")) |> render_click() =~
               gettext("New Ammo type")

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :new))

      # assert index_live
      #        |> form("#ammo_type-form", ammo_type: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form", ammo_type: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ dgettext("prompts", "%{name} created successfully", name: ammo_type.name)
      assert html =~ "some bullet_type"
    end

    test "updates ammo_type in listing",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"edit-#{ammo_type.id}\"]") |> render_click() =~
               gettext("Edit Ammo type")

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :edit, ammo_type))

      # assert index_live
      #        |> form("#ammo_type-form", ammo_type: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form", ammo_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ dgettext("prompts", "%{name} updated successfully", name: ammo_type.name)
      assert html =~ "some updated bullet_type"
    end

    test "deletes ammo_type in listing", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{ammo_type.id}\"]") |> render_click()
      refute has_element?(index_live, "#ammo_type-#{ammo_type.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_ammo_type]

    test "displays ammo_type", %{conn: conn, ammo_type: ammo_type} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ gettext("Show Ammo type")
      assert html =~ ammo_type.bullet_type
    end

    test "updates ammo_type within modal",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert show_live |> element("[data-qa=\"edit\"]") |> render_click() =~
               gettext("Edit Ammo type")

      assert_patch(show_live, Routes.ammo_type_show_path(conn, :edit, ammo_type))

      # assert show_live
      #        |> form("#ammo_type-form", ammo_type: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        show_live
        |> form("#ammo_type-form", ammo_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ dgettext("prompts", "%{name} updated successfully", name: ammo_type.name)
      assert html =~ "some updated bullet_type"
    end
  end
end
