defmodule CanneryWeb.ContainerLiveTest do
  @moduledoc """
  Tests the containers liveviews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.Containers

  @moduletag :container_live_test

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

  # @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}

  defp create_container(%{current_user: current_user}) do
    container = container_fixture(@create_attrs, current_user)
    %{container: container}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_container]

    test "lists all containers", %{conn: conn, container: container} do
      {:ok, _index_live, html} = live(conn, Routes.container_index_path(conn, :index))

      assert html =~ gettext("Containers")
      assert html =~ container.location
    end

    test "saves new container", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "New Container")) |> render_click() =~
               gettext("New Container")

      assert_patch(index_live, Routes.container_index_path(conn, :new))

      # assert index_live
      #        |> form("#container-form", container: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#container-form", container: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      assert html =~ dgettext("prompts", "%{name} created successfully", name: container.name)
      assert html =~ "some location"
    end

    test "updates container in listing", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"edit-#{container.id}\"]") |> render_click() =~
               gettext("Edit Container")

      assert_patch(index_live, Routes.container_index_path(conn, :edit, container))

      # assert index_live
      #        |> form("#container-form", container: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        index_live
        |> form("#container-form", container: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_index_path(conn, :index))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ dgettext("prompts", "%{name} updated successfully", name: container.name)
      assert html =~ "some updated location"
    end

    test "deletes container in listing", %{conn: conn, container: container} do
      {:ok, index_live, _html} = live(conn, Routes.container_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{container.id}\"]") |> render_click()
      refute has_element?(index_live, "#container-#{container.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_container]

    test "displays container", %{conn: conn, container: container} do
      {:ok, _show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ gettext("Show Container")
      assert html =~ container.location
    end

    test "updates container within modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert show_live |> element("[data-qa=\"edit\"]") |> render_click() =~
               gettext("Edit Container")

      assert_patch(show_live, Routes.container_show_path(conn, :edit, container))

      # assert show_live
      #        |> form("#container-form", container: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _, html} =
        show_live
        |> form("#container-form", container: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_show_path(conn, :show, container))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ dgettext("prompts", "%{name} updated successfully", name: container.name)
      assert html =~ "some updated location"
    end
  end
end
