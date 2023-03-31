defmodule CanneryWeb.TypeLiveTest do
  @moduledoc """
  Tests the type liveview
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Cannery.{Ammo, Repo}

  @moduletag :type_live_test

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

  defp create_type(%{current_user: current_user}) do
    [type: type_fixture(@create_attrs, current_user)]
  end

  defp create_pack(%{type: type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, type, container, current_user)
    [pack: pack, container: container]
  end

  defp create_empty_pack(%{type: type, current_user: current_user}) do
    container = container_fixture(current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, type, container, current_user)
    shot_record = shot_record_fixture(@shot_record_attrs, current_user, pack)
    pack = pack |> Repo.reload!()
    [pack: pack, container: container, shot_record: shot_record]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_type]

    test "lists all types", %{conn: conn, type: type} do
      {:ok, _index_live, html} = live(conn, Routes.type_index_path(conn, :index))
      assert html =~ "Catalog"
      assert html =~ type.bullet_type
    end

    test "can sort by class", %{conn: conn, current_user: current_user} do
      rifle_type = type_fixture(%{class: :rifle}, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)

      {:ok, index_live, html} = live(conn, Routes.type_index_path(conn, :index))

      assert html =~ "All"

      assert html =~ rifle_type.name
      assert html =~ shotgun_type.name
      assert html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :rifle})

      assert html =~ rifle_type.name
      refute html =~ shotgun_type.name
      refute html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :shotgun})

      refute html =~ rifle_type.name
      assert html =~ shotgun_type.name
      refute html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :pistol})

      refute html =~ rifle_type.name
      refute html =~ shotgun_type.name
      assert html =~ pistol_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :all})

      assert html =~ rifle_type.name
      assert html =~ shotgun_type.name
      assert html =~ pistol_type.name
    end

    test "can search for type", %{conn: conn, type: type} do
      {:ok, index_live, html} = live(conn, Routes.type_index_path(conn, :index))

      assert html =~ type.bullet_type

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: type.bullet_type}) =~
               type.bullet_type

      assert_patch(index_live, Routes.type_index_path(conn, :search, type.bullet_type))

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ type.bullet_type

      assert_patch(index_live, Routes.type_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ type.bullet_type

      assert_patch(index_live, Routes.type_index_path(conn, :index))
    end

    test "saves new type", %{conn: conn, current_user: current_user, type: type} do
      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))

      assert index_live |> element("a", "New Type") |> render_click() =~ "New Type"
      assert_patch(index_live, Routes.type_index_path(conn, :new))

      assert index_live
             |> form("#type-form")
             |> render_change(type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#type-form")
        |> render_submit(type: @create_attrs)
        |> follow_redirect(conn, Routes.type_index_path(conn, :index))

      type = type.id |> Ammo.get_type!(current_user)
      assert html =~ "#{type.name} created successfully"
      assert html =~ "some bullet_type"
    end

    test "updates type in listing",
         %{conn: conn, current_user: current_user, type: type} do
      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))

      assert index_live |> element(~s/a[aria-label="Edit #{type.name}"]/) |> render_click() =~
               "Edit #{type.name}"

      assert_patch(index_live, Routes.type_index_path(conn, :edit, type))

      assert index_live
             |> form("#type-form")
             |> render_change(type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#type-form")
        |> render_submit(type: @update_attrs)
        |> follow_redirect(conn, Routes.type_index_path(conn, :index))

      type = type.id |> Ammo.get_type!(current_user)
      assert html =~ "#{type.name} updated successfully"
      assert html =~ "some updated bullet_type"
    end

    test "clones type in listing",
         %{conn: conn, current_user: current_user, type: type} do
      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))

      html = index_live |> element(~s/a[aria-label="Clone #{type.name}"]/) |> render_click()
      assert html =~ "New Type"
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.type_index_path(conn, :clone, type))

      assert index_live
             |> form("#type-form")
             |> render_change(type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#type-form")
        |> render_submit(type: @create_attrs)
        |> follow_redirect(conn, Routes.type_index_path(conn, :index))

      type = type.id |> Ammo.get_type!(current_user)
      assert html =~ "#{type.name} created successfully"
      assert html =~ "some bullet_type"
    end

    test "clones type in listing with updates",
         %{conn: conn, current_user: current_user, type: type} do
      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))

      html = index_live |> element(~s/a[aria-label="Clone #{type.name}"]/) |> render_click()
      assert html =~ "New Type"
      assert html =~ "some bullet_type"

      assert_patch(index_live, Routes.type_index_path(conn, :clone, type))

      assert index_live
             |> form("#type-form")
             |> render_change(type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#type-form")
        |> render_submit(
          type: Map.merge(@create_attrs, %{bullet_type: "some updated bullet_type"})
        )
        |> follow_redirect(conn, Routes.type_index_path(conn, :index))

      type = type.id |> Ammo.get_type!(current_user)
      assert html =~ "#{type.name} created successfully"
      assert html =~ "some updated bullet_type"
    end

    test "deletes type in listing", %{conn: conn, type: type} do
      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))
      assert index_live |> element(~s/a[aria-label="Delete #{type.name}"]/) |> render_click()
      refute has_element?(index_live, "#type-#{type.id}")
    end
  end

  describe "Index with pack" do
    setup [:register_and_log_in_user, :create_type, :create_pack]

    test "shows used packs on toggle",
         %{conn: conn, pack: pack, current_user: current_user} do
      {:ok, index_live, html} = live(conn, Routes.type_index_path(conn, :index))

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

      {:ok, index_live, _html} = live(conn, Routes.type_index_path(conn, :index))

      html =
        index_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "\n15\n"
      assert html =~ "\n5\n"
    end
  end

  describe "Show type" do
    setup [:register_and_log_in_user, :create_type]

    test "displays type", %{
      conn: conn,
      type: %{name: name, bullet_type: bullet_type} = type
    } do
      {:ok, _show_live, html} = live(conn, Routes.type_show_path(conn, :show, type))

      assert html =~ name
      assert html =~ bullet_type
    end

    test "updates type within modal",
         %{conn: conn, current_user: current_user, type: %{name: name} = type} do
      {:ok, show_live, _html} = live(conn, Routes.type_show_path(conn, :show, type))

      assert show_live |> element(~s/a[aria-label="Edit #{type.name}"]/) |> render_click() =~
               "Edit #{name}"

      assert_patch(show_live, Routes.type_show_path(conn, :edit, type))

      assert show_live
             |> form("#type-form")
             |> render_change(type: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#type-form")
        |> render_submit(type: @update_attrs)
        |> follow_redirect(conn, Routes.type_show_path(conn, :show, type))

      type = type.id |> Ammo.get_type!(current_user)
      assert html =~ "#{type.name} updated successfully"
      assert html =~ "some updated bullet_type"
    end
  end

  describe "Show type with pack" do
    setup [:register_and_log_in_user, :create_type, :create_pack]

    test "displays pack", %{
      conn: conn,
      type: %{name: type_name} = type,
      container: %{name: container_name}
    } do
      {:ok, _show_live, html} = live(conn, Routes.type_show_path(conn, :show, type))

      assert html =~ type_name
      assert html =~ "\n20\n"
      assert html =~ container_name
    end

    test "displays pack in table",
         %{conn: conn, type: type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.type_show_path(conn, :show, type))

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ "\n20\n"
      assert html =~ container_name
    end
  end

  describe "Show type with empty pack" do
    setup [:register_and_log_in_user, :create_type, :create_empty_pack]

    test "displays empty packs on toggle",
         %{conn: conn, type: type, container: %{name: container_name}} do
      {:ok, show_live, html} = live(conn, Routes.type_show_path(conn, :show, type))
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
         %{conn: conn, type: type, container: %{name: container_name}} do
      {:ok, show_live, _html} = live(conn, Routes.type_show_path(conn, :show, type))

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
