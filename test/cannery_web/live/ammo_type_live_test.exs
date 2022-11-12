defmodule CanneryWeb.AmmoTypeLiveTest do
  @moduledoc """
  Tests the ammo type liveview
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.{Ammo, Repo}

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
  @ammo_group_attrs %{
    "notes" => "some ammo group",
    "count" => 20
  }
  @shot_group_attrs %{
    "notes" => "some shot group",
    "count" => 20
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

  defp create_ammo_group(%{ammo_type: ammo_type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [ammo_group]} = ammo_group_fixture(@ammo_group_attrs, ammo_type, container, current_user)

    %{ammo_group: ammo_group, container: container}
  end

  defp create_empty_ammo_group(%{ammo_type: ammo_type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [ammo_group]} = ammo_group_fixture(@ammo_group_attrs, ammo_type, container, current_user)
    shot_group = shot_group_fixture(@shot_group_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()

    %{ammo_group: ammo_group, container: container, shot_group: shot_group}
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

    test "clones ammo_type in listing",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      html = index_live |> element("[data-qa=\"clone-#{ammo_type.id}\"]") |> render_click()
      assert html =~ gettext("New Ammo type")
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :clone, ammo_type))

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

    test "clones ammo_type in listing with updates",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      html = index_live |> element("[data-qa=\"clone-#{ammo_type.id}\"]") |> render_click()
      assert html =~ gettext("New Ammo type")
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :clone, ammo_type))

      # assert index_live
      #        |> form("#ammo_type-form", ammo_type: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form",
          ammo_type: Map.merge(@create_attrs, %{"bullet_type" => "some updated bullet_type"})
        )
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ dgettext("prompts", "%{name} created successfully", name: ammo_type.name)
      assert html =~ "some updated bullet_type"
    end

    test "deletes ammo_type in listing", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{ammo_type.id}\"]") |> render_click()
      refute has_element?(index_live, "#ammo_type-#{ammo_type.id}")
    end
  end

  describe "Index with ammo group" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_ammo_group]

    test "shows used ammo groups on toggle",
         %{conn: conn, ammo_group: ammo_group, current_user: current_user} do
      {:ok, index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ dgettext("actions", "Show used")
      refute html =~ gettext("Used rounds")
      refute html =~ gettext("Total ever rounds")
      refute html =~ gettext("Used packs")
      refute html =~ gettext("Total ever packs")

      html = index_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ gettext("Used rounds")
      assert html =~ gettext("Total ever rounds")
      assert html =~ gettext("Used packs")
      assert html =~ gettext("Total ever packs")

      assert html =~ "20"
      assert html =~ "0"
      assert html =~ "1"

      shot_group_fixture(%{"count" => 5}, current_user, ammo_group)

      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))
      html = index_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ "15"
      assert html =~ "5"
    end
  end

  describe "Show ammo type" do
    setup [:register_and_log_in_user, :create_ammo_type]

    test "displays ammo_type", %{
      conn: conn,
      ammo_type: %{name: name, bullet_type: bullet_type} = ammo_type
    } do
      {:ok, _show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ name
      assert html =~ bullet_type
    end

    test "updates ammo_type within modal",
         %{conn: conn, current_user: current_user, ammo_type: %{name: name} = ammo_type} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert show_live |> element("[data-qa=\"edit\"]") |> render_click() =~
               gettext("Edit %{ammo_type_name}", ammo_type_name: name)

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

  describe "Show ammo type with ammo group" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_ammo_group]

    test "displays ammo group", %{
      conn: conn,
      ammo_type: %{name: ammo_type_name} = ammo_type,
      container: %{name: container_name}
    } do
      {:ok, _show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ ammo_type_name
      assert html =~ "some ammo group"
      assert html =~ container_name
    end

    test "displays ammo group in table",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      html = show_live |> element("[data-qa=\"toggle_table\"]") |> render_click()
      assert_patch(show_live, Routes.ammo_type_show_path(conn, :table, ammo_type))

      assert html =~ "some ammo group"
      assert html =~ container_name
    end
  end

  describe "Show ammo type with empty ammo group" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_empty_ammo_group]

    test "displays empty ammo groups on toggle",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ dgettext("actions", "Show used")
      refute html =~ "some ammo group"

      html = show_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ "some ammo group"
      assert html =~ "Empty"
      assert html =~ container_name
    end

    test "displays empty ammo groups in table on toggle",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      html = show_live |> element("[data-qa=\"toggle_table\"]") |> render_click()
      assert_patch(show_live, Routes.ammo_type_show_path(conn, :table, ammo_type))

      assert html =~ dgettext("actions", "Show used")
      refute html =~ "some ammo group"

      html = show_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ "some ammo group"
      assert html =~ "Empty"
      assert html =~ container_name
    end
  end
end
