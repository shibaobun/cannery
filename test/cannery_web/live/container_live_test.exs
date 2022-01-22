defmodule CanneryWeb.ContainerLiveTest do
  use CanneryWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Cannery.Containers

  @create_attrs %{
    "desc" => "some desc",
    "location" => "some location",
    "name" => "some name",
    "type" => "some type"
  }
  @update_attrs %{
    "desc" => "some updated desc",
    "location" => "some updated location",
    "name" => "some updated name",
    "type" => "some updated type"
  }
  @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}

  defp fixture(:container) do
    {:ok, container} = Containers.create_container(@create_attrs)
    container
  end

  defp create_container(_) do
    container = fixture(:container)
    %{container: container}
  end

  describe "Index" do
    setup [:create_container]

    test "lists all containers", %{conn: conn, container: container} do
      {:ok, _index_live, html} = live(conn, Routes.container_index_path(conn, :index))

      assert html =~ "Listing Containers"
      assert html =~ container.desc
    end

    test "saves new container", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("a", "New Container") |> render_click() =~
               "New Container"

      assert_patch(index_live, Routes.container_index_path(conn, :new))

      assert index_live
             |> form("#container-form", container: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#container-form", container: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      assert html =~ "Container created successfully"
      assert html =~ "some desc"
    end

    test "updates container in listing", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("#container-#{container.id} a", "Edit") |> render_click() =~
               "Edit Container"

      assert_patch(index_live, Routes.container_index_path(conn, :edit, container))

      assert index_live
             |> form("#container-form", container: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#container-form", container: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      assert html =~ "Container updated successfully"
      assert html =~ "some updated desc"
    end

    test "deletes container in listing", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("#container-#{container.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#container-#{container.id}")
    end
  end

  describe "Show" do
    setup [:create_container]

    test "displays container", %{conn: conn, container: container} do
      {:ok, _show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ "Show Container"
      assert html =~ container.desc
    end

    test "updates container within modal", %{conn: conn, container: container} do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Container"

      assert_patch(show_live, Routes.container_show_path(conn, :edit, container))

      assert show_live
             |> form("#container-form", container: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#container-form", container: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ "Container updated successfully"
      assert html =~ "some updated desc"
    end
  end
end
