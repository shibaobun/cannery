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
  @ammo_type_attrs %{
    bullet_type: "some bullet_type",
    case_material: "some case_material",
    desc: "some desc",
    manufacturer: "some manufacturer",
    name: "some name",
    grains: 120
  }
  @ammo_group_attrs %{
    notes: "some ammo group",
    count: 20
  }

  defp create_container(%{current_user: current_user}) do
    container = container_fixture(@create_attrs, current_user)
    [container: container]
  end

  defp create_ammo_group(%{container: container, current_user: current_user}) do
    ammo_type = ammo_type_fixture(@ammo_type_attrs, current_user)
    {1, [ammo_group]} = ammo_group_fixture(@ammo_group_attrs, ammo_type, container, current_user)

    [ammo_type: ammo_type, ammo_group: ammo_group]
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
      rifle_type = ammo_type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_ammo_group]} = ammo_group_fixture(rifle_type, container, current_user)
      shotgun_type = ammo_type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_ammo_group]} = ammo_group_fixture(shotgun_type, container, current_user)
      pistol_type = ammo_type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_ammo_group]} = ammo_group_fixture(pistol_type, container, current_user)

      {:ok, index_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ "All"

      assert html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :rifle})

      assert html =~ rifle_ammo_group.ammo_type.name
      refute html =~ shotgun_ammo_group.ammo_type.name
      refute html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :shotgun})

      refute html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      refute html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :pistol})

      refute html =~ rifle_ammo_group.ammo_type.name
      refute html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_class"]/)
        |> render_change(ammo_type: %{class: :all})

      assert html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name
    end
  end

  describe "Show with ammo group" do
    setup [:register_and_log_in_user, :create_container, :create_ammo_group]

    test "displays ammo group",
         %{conn: conn, ammo_type: %{name: ammo_type_name}, container: container} do
      {:ok, _show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ ammo_type_name
      assert html =~ "\n20\n"
    end

    test "displays ammo group in table",
         %{conn: conn, ammo_type: %{name: ammo_type_name}, container: container} do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_table-label"}]/)
        |> render_click()

      assert html =~ ammo_type_name
      assert html =~ "\n20\n"
    end
  end
end
