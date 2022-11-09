defmodule CanneryWeb.ContainerLiveTest do
  @moduledoc """
  Tests the containers liveviews
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.{Containers, Repo}

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
  @ammo_type_attrs %{
    "bullet_type" => "some bullet_type",
    "case_material" => "some case_material",
    "desc" => "some desc",
    "manufacturer" => "some manufacturer",
    "name" => "some name",
    "grains" => 120
  }
  @ammo_group_attrs %{
    "notes" => "some ammo group",
    "count" => 20
  }
  @shot_group_attrs %{
    "notes" => "some shot group",
    "count" => 20
  }

  # @invalid_attrs %{desc: nil, location: nil, name: nil, type: nil}

  defp create_container(%{current_user: current_user}) do
    container = container_fixture(@create_attrs, current_user)
    %{container: container}
  end

  defp create_empty_ammo_group(%{container: container, current_user: current_user}) do
    ammo_type = ammo_type_fixture(@ammo_type_attrs, current_user)
    {1, [ammo_group]} = ammo_group_fixture(@ammo_group_attrs, ammo_type, container, current_user)
    shot_group = shot_group_fixture(@shot_group_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()

    %{ammo_group: ammo_group, shot_group: shot_group}
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

      {:ok, _view, html} =
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
               gettext("Edit %{name}", name: container.name)

      assert_patch(index_live, Routes.container_index_path(conn, :edit, container))

      # assert index_live
      #        |> form("#container-form", container: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
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

      assert html =~ gettext("Show %{name}", name: container.name)
      assert html =~ container.location
    end

    test "updates container within modal", %{
      conn: conn,
      current_user: current_user,
      container: container
    } do
      {:ok, show_live, _html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert show_live |> element("[data-qa=\"edit\"]") |> render_click() =~
               gettext("Edit %{name}", name: container.name)

      assert_patch(show_live, Routes.container_show_path(conn, :edit, container))

      # assert show_live
      #        |> form("#container-form", container: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        show_live
        |> form("#container-form", container: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.container_show_path(conn, :show, container))

      container = container.id |> Containers.get_container!(current_user)
      assert html =~ dgettext("prompts", "%{name} updated successfully", name: container.name)
      assert html =~ "some updated location"
    end
  end

  describe "Show with empty ammo group" do
    setup [:register_and_log_in_user, :create_container, :create_empty_ammo_group]

    test "hides empty ammo groups by default",
         %{conn: conn, container: container} do
      {:ok, show_live, html} = live(conn, Routes.container_show_path(conn, :show, container))

      assert html =~ dgettext("actions", "Show used")
      refute html =~ "some ammo group"

      html = show_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ "some ammo group"
      assert html =~ "Empty"
    end
  end
end
