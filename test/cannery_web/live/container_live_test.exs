defmodule CanneryWeb.ContainerLiveTest do
  @moduledoc """
  Tests the containers liveviews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Cannery.Containers

  @moduletag :container_live_test

  @create_attrs %{
    desc: "some desc",
    location: "some location",
    name: "some name",
    type: "some type"
  }
  @update_attrs %{
    desc: "some updated desc",
    location: "some updated location",
    name: "some updated name",
    type: "some updated type"
  }
  @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}
  @type_attrs %{
    bullet_type: "some bullet_type",
    case_material: "some case_material",
    desc: "some desc",
    manufacturer: "some manufacturer",
    name: "some name",
    grains: 120
  }
  @pack_attrs %{
    notes: "some pack",
    count: 20
  }

  defp create_container(%{current_user: current_user}) do
    container = container_fixture(@create_attrs, current_user)
    [container: container]
  end

  defp create_pack(%{container: container, current_user: current_user}) do
    type = type_fixture(@type_attrs, current_user)
    {1, [pack]} = pack_fixture(@pack_attrs, type, container, current_user)

    [type: type, pack: pack]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_container]

    test "lists all containers", %{conn: conn, container: container} do
      {:ok, _index_live, html} = live(conn, Routes.container_index_path(conn, :index))

      assert html =~ "Containers"
      assert html =~ container.location
    end

    test "lists all containers in table mode", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      html =
        index_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ "Containers"
      assert html =~ container.location
    end

    test "can search for containers", %{conn: conn, container: container} do
      {:ok, index_live, html} = live(conn, Routes.container_index_path(conn, :index))

      assert html =~ container.location

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: container.location}) =~ container.location

      assert_patch(index_live, Routes.container_index_path(conn, :search, container.location))

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~ container.location

      assert_patch(index_live, Routes.container_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ container.location

      assert_patch(index_live, Routes.container_index_path(conn, :index))
    end

    test "saves new container", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("a", "New Container") |> render_click() =~ "New Container"
      assert_patch(index_live, Routes.container_index_path(conn, :new))

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @create_attrs)
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      assert html =~ "#{container.name} created successfully"
      assert html =~ "some location"
    end

    test "updates container in listing", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element(~s/a[aria-label="Edit #{container.name}"]/) |> render_click() =~
               "Edit #{container.name}"

      assert_patch(index_live, Routes.container_index_path(conn, :edit, container))

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @update_attrs)
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} updated successfully"
      assert html =~ "some updated location"
    end

    test "clones container in listing", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      html = index_live |> element(~s/a[aria-label="Clone #{container.name}"]/) |> render_click()
      assert html =~ "New Container"
      assert html =~ "some location"

      assert_patch(index_live, Routes.container_index_path(conn, :clone, container))

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(container: @create_attrs)
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} created successfully"
      assert html =~ "some location"
    end

    test "clones container in listing with updates", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element(~s/a[aria-label="Clone #{container.name}"]/) |> render_click() =~
               "New Container"

      assert_patch(index_live, Routes.container_index_path(conn, :clone, container))

      assert index_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#container-form")
        |> render_submit(
          container: Map.merge(@create_attrs, %{location: "some updated location"})
        )
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} created successfully"
      assert html =~ "some updated location"
    end

    test "deletes container in listing", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))
      assert index_live |> element(~s/a[aria-label="Delete #{container.name}"]/) |> render_click()
      refute has_element?(index_live, "#container-#{container.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_container]

    test "displays container", %{
      conn: conn,
      container: %{name: name, location: location} = container
    } do
      {:ok, _show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))
      assert html =~ name
      assert html =~ location
    end

    test "updates container within modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert show_live |> element(~s/a[aria-label="Edit #{container.name}"]/) |> render_click() =~
               "Edit #{container.name}"

      assert_patch(show_live, Routes.container_show_path(conn, :edit, container))

      assert show_live
             |> form("#container-form")
             |> render_change(container: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#container-form")
        |> render_submit(container: @update_attrs)
        |> follow_redirect(conn, Routes.container_show_path(conn, :show, container))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ "#{container.name} updated successfully"
      assert html =~ "some updated location"
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)

      {:ok, index_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ "All"

      assert html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :rifle})

      assert html =~ rifle_pack.type.name
      refute html =~ shotgun_pack.type.name
      refute html =~ pistol_pack.type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :shotgun})

      refute html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      refute html =~ pistol_pack.type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :pistol})

      refute html =~ rifle_pack.type.name
      refute html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(type: %{class: :all})

      assert html =~ rifle_pack.type.name
      assert html =~ shotgun_pack.type.name
      assert html =~ pistol_pack.type.name
    end
  end

  describe "Show with pack" do
    setup [:register_and_log_in_user, :create_container, :create_pack]

    test "displays pack",
         %{conn: conn, type: %{name: type_name}, container: container} do
      {:ok, _show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ type_name
      assert html =~ "\n20\n"
    end

    test "displays pack in table",
         %{conn: conn, type: %{name: type_name}, container: container} do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ type_name
      assert html =~ "\n20\n"
    end
  end
end
