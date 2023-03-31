defmodule CanneryWeb.AmmoTypeLiveTest do
  @moduledoc """
  Tests the ammo type liveview
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Cannery.{Ammo, Repo}

  @moduletag :ammo_type_live_test

  @create_attrs %{
    bullet_type: "some bullet_type",
    case_material: "some case_material",
    desc: "some desc",
    manufacturer: "some manufacturer",
    name: "some name",
    grains: 120
  }
  @update_attrs %{
    bullet_type: "some updated bullet_type",
    case_material: "some updated case_material",
    desc: "some updated desc",
    manufacturer: "some updated manufacturer",
    name: "some updated name",
    grains: 456
  }
  @invalid_attrs %{
    bullet_type: nil,
    case_material: nil,
    desc: nil,
    manufacturer: nil,
    name: nil,
    grains: nil
  }
  @pack_attrs %{
    notes: "some pack",
    count: 20
  }
  @shot_record_attrs %{
    notes: "some shot recorddd",
    count: 20
  }

  defp create_ammo_type(%{current_user: current_user}) do
    [ammo_type: ammo_type_fixture(@create_attrs, current_user)]
  end

  defp create_pack(%{ammo_type: ammo_type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, ammo_type, container, current_user)
    [pack: pack, container: container]
  end

  defp create_empty_pack(%{ammo_type: ammo_type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, ammo_type, container, current_user)
    shot_record = shot_record_fixture(@shot_record_attrs, current_user, pack)
    pack = pack |> Repo.reload!()
    [pack: pack, container: container, shot_record: shot_record]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_ammo_type]

    test "lists all ammo_types", %{conn: conn, ammo_type: ammo_type} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))
      assert html =~ "Catalog"
      assert html =~ ammo_type.bullet_type
    end

    test "can sort by class", %{conn: conn, current_user: current_user} do
      rifle_type = ammo_type_fixture(%{class: :rifle}, current_user)
      shotgun_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      pistol_type = ammo_type_fixture(%{class: :pistol}, current_user)

      {:ok, index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ "All"

      assert html =~ rifle_type.name
      assert html =~ shotgun_type.name
      assert html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :rifle})

      assert html =~ rifle_type.name
      refute html =~ shotgun_type.name
      refute html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :shotgun})

      refute html =~ rifle_type.name
      assert html =~ shotgun_type.name
      refute html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :pistol})

      refute html =~ rifle_type.name
      refute html =~ shotgun_type.name
      assert html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :all})

      assert html =~ rifle_type.name
      assert html =~ shotgun_type.name
      assert html =~ pistol_type.name
    end

    test "can search for ammo_type", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ ammo_type.bullet_type

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ammo_type.bullet_type}) =~
               ammo_type.bullet_type

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :search, ammo_type.bullet_type))

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ ammo_type.bullet_type

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ ammo_type.bullet_type

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :index))
    end

    test "saves new ammo_type", %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element("a", "New Ammo type") |> render_click() =~ "New Ammo type"
      assert_patch(index_live, Routes.ammo_type_index_path(conn, :new))

      assert index_live
             |> form("#ammo_type-form")
             |> render_change(ammo_type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form")
        |> render_submit(ammo_type: @create_attrs)
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ "#{ammo_type.name} created successfully"
      assert html =~ "some bullet_type"
    end

    test "updates ammo_type in listing",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert index_live |> element(~s/a[aria-label="Edit #{ammo_type.name}"]/) |> render_click() =~
               "Edit #{ammo_type.name}"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :edit, ammo_type))

      assert index_live
             |> form("#ammo_type-form")
             |> render_change(ammo_type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form")
        |> render_submit(ammo_type: @update_attrs)
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ "#{ammo_type.name} updated successfully"
      assert html =~ "some updated bullet_type"
    end

    test "clones ammo_type in listing",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      html = index_live |> element(~s/a[aria-label="Clone #{ammo_type.name}"]/) |> render_click()
      assert html =~ "New Ammo type"
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :clone, ammo_type))

      assert index_live
             |> form("#ammo_type-form")
             |> render_change(ammo_type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form")
        |> render_submit(ammo_type: @create_attrs)
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ "#{ammo_type.name} created successfully"
      assert html =~ "some bullet_type"
    end

    test "clones ammo_type in listing with updates",
         %{conn: conn, current_user: current_user, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      html = index_live |> element(~s/a[aria-label="Clone #{ammo_type.name}"]/) |> render_click()
      assert html =~ "New Ammo type"
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.ammo_type_index_path(conn, :clone, ammo_type))

      assert index_live
             |> form("#ammo_type-form")
             |> render_change(ammo_type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_type-form")
        |> render_submit(
          ammo_type: Map.merge(@create_attrs, %{bullet_type: "some updated bullet_type"})
        )
        |> follow_redirect(conn, Routes.ammo_type_index_path(conn, :index))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ "#{ammo_type.name} created successfully"
      assert html =~ "some updated bullet_type"
    end

    test "deletes ammo_type in listing", %{conn: conn, ammo_type: ammo_type} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))
      assert index_live |> element(~s/a[aria-label="Delete #{ammo_type.name}"]/) |> render_click()
      refute has_element?(index_live, "#ammo_type-#{ammo_type.id}")
    end
  end

  describe "Index with pack" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_pack]

    test "shows used packs on toggle",
         %{conn: conn, pack: pack, current_user: current_user} do
      {:ok, index_live, html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      assert html =~ "Show used"
      refute html =~ "Used rounds"
      refute html =~ "Total ever rounds"
      refute html =~ "Used packs"
      refute html =~ "Total ever packs"

      html =
        index_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "Used rounds"
      assert html =~ "Total ever rounds"
      assert html =~ "Used packs"
      assert html =~ "Total ever packs"

      assert html =~ "\n20\n"
      assert html =~ "\n0\n"
      assert html =~ "\n1\n"

      shot_record_fixture(%{count: 5}, current_user, pack)

      {:ok, index_live, _html} = live(conn, Routes.ammo_type_index_path(conn, :index))

      html =
        index_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "\n15\n"
      assert html =~ "\n5\n"
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

      assert show_live |> element(~s/a[aria-label="Edit #{ammo_type.name}"]/) |> render_click() =~
               "Edit #{name}"

      assert_patch(show_live, Routes.ammo_type_show_path(conn, :edit, ammo_type))

      assert show_live
             |> form("#ammo_type-form")
             |> render_change(ammo_type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#ammo_type-form")
        |> render_submit(ammo_type: @update_attrs)
        |> follow_redirect(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      ammo_type = ammo_type.id |> Ammo.get_ammo_type!(current_user)
      assert html =~ "#{ammo_type.name} updated successfully"
      assert html =~ "some updated bullet_type"
    end
  end

  describe "Show ammo type with pack" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_pack]

    test "displays pack", %{
      conn: conn,
      ammo_type: %{name: ammo_type_name} = ammo_type,
      container: %{name: container_name}
    } do
      {:ok, _show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      assert html =~ ammo_type_name
      assert html =~ "\n20\n"
      assert html =~ container_name
    end

    test "displays pack in table",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ "\n20\n"
      assert html =~ container_name
    end
  end

  describe "Show ammo type with empty pack" do
    setup [:register_and_log_in_user, :create_ammo_type, :create_empty_pack]

    test "displays empty packs on toggle",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))
      assert html =~ "Show used"
      refute html =~ "\n20\n"

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "\n20\n"
      assert html =~ "Empty"
      assert html =~ container_name
    end

    test "displays empty packs in table on toggle",
         %{conn: conn, ammo_type: ammo_type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_type_show_path(conn, :show, ammo_type))

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ "Show used"
      refute html =~ "\n20\n"

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "\n20\n"
      assert html =~ "Empty"
      assert html =~ container_name
    end
  end
end
