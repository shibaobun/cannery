defmodule CanneryWeb.AmmoGroupLiveTest do
  @moduledoc """
  Tests ammo group live pages
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  import CanneryWeb.Gettext
  alias Cannery.{Ammo, Repo}

  @moduletag :ammo_group_live_test
  @shot_group_create_attrs %{"ammo_left" => 5, "notes" => "some notes"}
  @shot_group_update_attrs %{
    "count" => 5,
    "date" => ~N[2022-02-13 03:17:00],
    "notes" => "some updated notes"
  }
  @create_attrs %{"count" => 42, "notes" => "some notes", "price_paid" => 120.5}
  @update_attrs %{"count" => 43, "notes" => "some updated notes", "price_paid" => 456.7}
  @ammo_group_create_limit 10_000
  @empty_attrs %{
    "price_paid" => 50,
    "count" => 20
  }
  @shot_group_attrs %{
    "price_paid" => 50,
    "count" => 20
  }

  # @invalid_attrs %{count: -1, notes: nil, price_paid: nil}

  defp create_ammo_group(%{current_user: current_user}) do
    ammo_type = ammo_type_fixture(current_user)
    container = container_fixture(current_user)
    {1, [ammo_group]} = ammo_group_fixture(@create_attrs, ammo_type, container, current_user)

    %{ammo_type: ammo_type, ammo_group: ammo_group, container: container}
  end

  defp create_shot_group(%{current_user: current_user, ammo_group: ammo_group}) do
    shot_group = shot_group_fixture(@shot_group_update_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()

    %{ammo_group: ammo_group, shot_group: shot_group}
  end

  defp create_empty_ammo_group(%{
         current_user: current_user,
         ammo_type: ammo_type,
         container: container
       }) do
    {1, [ammo_group]} = ammo_group_fixture(@empty_attrs, ammo_type, container, current_user)
    shot_group = shot_group_fixture(@shot_group_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()
    %{empty_ammo_group: ammo_group, shot_group: shot_group}
  end

  describe "Index of ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "lists all ammo_groups", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ gettext("Ammo")
      assert html =~ ammo_group.ammo_type.name
    end

    test "saves a single new ammo_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Add Ammo")) |> render_click() =~
               dgettext("actions", "Add Ammo")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo added successfully")
      assert html =~ "42"
    end

    test "saves multiple new ammo_groups", %{conn: conn, current_user: current_user} do
      multiplier = 25

      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Add Ammo")) |> render_click() =~
               dgettext("actions", "Add Ammo")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form",
          ammo_group: @create_attrs |> Map.put("multiplier", to_string(multiplier))
        )
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo added successfully")
      assert Ammo.list_ammo_groups(current_user) |> Enum.count() == multiplier + 1
    end

    test "does not save invalid number of new ammo_groups", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Add Ammo")) |> render_click() =~
               dgettext("actions", "Add Ammo")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      assert index_live
             |> form("#ammo_group-form", ammo_group: @create_attrs |> Map.put("multiplier", "0"))
             |> render_submit() =~
               dgettext(
                 "errors",
                 "Invalid number of copies, must be between 1 and %{max}. Was %{multiplier}",
                 multiplier: 0,
                 max: @ammo_group_create_limit
               )

      assert index_live
             |> form("#ammo_group-form",
               ammo_group:
                 @create_attrs |> Map.put("multiplier", to_string(@ammo_group_create_limit + 1))
             )
             |> render_submit() =~
               dgettext(
                 "errors",
                 "Invalid number of copies, must be between 1 and %{max}. Was %{multiplier}",
                 multiplier: @ammo_group_create_limit + 1,
                 max: @ammo_group_create_limit
               )
    end

    test "updates ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element("[data-qa=\"edit-#{ammo_group.id}\"]")
             |> render_click() =~
               gettext("Edit Ammo")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :edit, ammo_group))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo updated successfully")
      assert html =~ "43"
    end

    test "clones ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      html =
        index_live
        |> element("[data-qa=\"clone-#{ammo_group.id}\"]")
        |> render_click()

      assert html =~ dgettext("actions", "Add Ammo")
      assert html =~ gettext("$%{amount}", amount: 120.5 |> :erlang.float_to_binary(decimals: 2))

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :clone, ammo_group))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo added successfully")
      assert html =~ "42"
      assert html =~ gettext("$%{amount}", amount: 120.5 |> :erlang.float_to_binary(decimals: 2))
    end

    test "clones ammo_group in listing with updates", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      html =
        index_live
        |> element("[data-qa=\"clone-#{ammo_group.id}\"]")
        |> render_click()

      assert html =~ dgettext("actions", "Add Ammo")
      assert html =~ gettext("$%{amount}", amount: 120.5 |> :erlang.float_to_binary(decimals: 2))

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :clone, ammo_group))

      # assert index_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form", ammo_group: Map.merge(@create_attrs, %{"count" => 43}))
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Ammo added successfully")
      assert html =~ "43"
      assert html =~ gettext("$%{amount}", amount: 120.5 |> :erlang.float_to_binary(decimals: 2))
    end

    test "deletes ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element("[data-qa=\"delete-#{ammo_group.id}\"]")
             |> render_click()

      refute has_element?(index_live, "#ammo_group-#{ammo_group.id}")
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Record shots")) |> render_click() =~
               gettext("Record shots")

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :add_shot_group, ammo_group))

      # assert index_live
      #        |> form("#shot_group-form", shot_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "is invalid")

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @shot_group_create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("prompts", "Shots recorded successfully")
    end
  end

  describe "Index of empty ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group, :create_empty_ammo_group]

    test "hides empty ammo groups by default", %{conn: conn, empty_ammo_group: ammo_group} do
      {:ok, show_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ dgettext("actions", "Show used")
      refute html =~ gettext("$%{amount}", amount: 50.00 |> :erlang.float_to_binary(decimals: 2))

      refute html =~
               "\n" <>
                 gettext("%{percentage}%",
                   percentage: ammo_group |> Ammo.get_percentage_remaining()
                 ) <>
                 "\n"

      html = show_live |> element("[data-qa=\"toggle_show_used\"]") |> render_click()

      assert html =~ gettext("$%{amount}", amount: 50.00 |> :erlang.float_to_binary(decimals: 2))

      assert html =~
               "\n" <>
                 gettext("%{percentage}%",
                   percentage: ammo_group |> Ammo.get_percentage_remaining()
                 ) <>
                 "\n"
    end
  end

  describe "Show ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "displays ammo_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ gettext("Show Ammo")
      assert html =~ ammo_group.ammo_type.name
    end

    test "updates ammo_group within modal", %{conn: conn, ammo_group: ammo_group} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert show_live
             |> element("[data-qa=\"edit\"]")
             |> render_click() =~
               gettext("Edit Ammo")

      assert_patch(show_live, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      # assert show_live
      #        |> form("#ammo_group-form", ammo_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _view, html} =
        show_live
        |> form("#ammo_group-form", ammo_group: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ dgettext("prompts", "Ammo updated successfully")
      assert html =~ "some updated notes"
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert index_live |> element("a", dgettext("actions", "Record shots")) |> render_click() =~
               gettext("Record shots")

      assert_patch(index_live, Routes.ammo_group_show_path(conn, :add_shot_group, ammo_group))

      # assert index_live
      #        |> form("#shot_group-form", shot_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "is invalid")

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @shot_group_create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ dgettext("prompts", "Shots recorded successfully")
    end
  end

  describe "Show ammo group with shot group" do
    setup [:register_and_log_in_user, :create_ammo_group, :create_shot_group]

    test "updates shot_group in listing",
         %{conn: conn, ammo_group: ammo_group, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      assert index_live |> element("[data-qa=\"edit-#{shot_group.id}\"]") |> render_click() =~
               gettext("Edit Shot Records")

      assert_patch(
        index_live,
        Routes.ammo_group_show_path(conn, :edit_shot_group, ammo_group, shot_group)
      )

      # assert index_live
      #        |> form("#shot_group-form", shot_group: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "is invalid")

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form", shot_group: @shot_group_update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ dgettext("actions", "Shot records updated successfully")
      assert html =~ "some updated notes"
    end

    test "deletes shot_group in listing",
         %{conn: conn, ammo_group: ammo_group, shot_group: shot_group} do
      {:ok, index_live, _html} =
        live(conn, Routes.ammo_group_show_path(conn, :edit_shot_group, ammo_group, shot_group))

      assert index_live |> element("[data-qa=\"delete-#{shot_group.id}\"]") |> render_click()
      refute has_element?(index_live, "#shot_group-#{shot_group.id}")
    end
  end
end
