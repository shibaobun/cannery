defmodule CanneryWeb.AmmoGroupLiveTest do
  @moduledoc """
  Tests ammo group live pages
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Cannery.{Ammo, Repo}

  @moduletag :ammo_group_live_test
  @create_attrs %{count: 42, notes: "some notes", price_paid: 120.5}
  @update_attrs %{count: 43, notes: "some updated notes", price_paid: 456.7}
  @invalid_attrs %{count: nil, notes: nil, price_paid: nil}
  @ammo_group_create_limit 10_000
  @shot_group_create_attrs %{ammo_left: 5, notes: "some notes"}
  @shot_group_update_attrs %{
    count: 5,
    date: ~N[2022-02-13 03:17:00],
    notes: "some updated notes"
  }
  @shot_group_invalid_attrs %{ammo_left: nil, count: nil, notes: nil}
  @empty_attrs %{
    price_paid: 50,
    count: 20
  }
  @shot_group_attrs %{
    price_paid: 50,
    count: 20
  }

  defp create_ammo_group(%{current_user: current_user}) do
    ammo_type = ammo_type_fixture(current_user)
    container = container_fixture(current_user)
    {1, [ammo_group]} = ammo_group_fixture(@create_attrs, ammo_type, container, current_user)
    [ammo_type: ammo_type, ammo_group: ammo_group, container: container]
  end

  defp create_shot_group(%{current_user: current_user, ammo_group: ammo_group}) do
    shot_group = shot_group_fixture(@shot_group_update_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()
    [ammo_group: ammo_group, shot_group: shot_group]
  end

  defp create_empty_ammo_group(%{
         current_user: current_user,
         ammo_type: ammo_type,
         container: container
       }) do
    {1, [ammo_group]} = ammo_group_fixture(@empty_attrs, ammo_type, container, current_user)
    shot_group = shot_group_fixture(@shot_group_attrs, current_user, ammo_group)
    ammo_group = ammo_group |> Repo.reload!()
    [empty_ammo_group: ammo_group, shot_group: shot_group]
  end

  describe "Index of ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "lists all ammo_groups", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))
      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ "Ammo"
      assert html =~ ammo_group.ammo_type.name
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_type = ammo_type_fixture(%{type: "rifle"}, current_user)
      {1, [rifle_ammo_group]} = ammo_group_fixture(rifle_type, container, current_user)
      shotgun_type = ammo_type_fixture(%{type: "shotgun"}, current_user)
      {1, [shotgun_ammo_group]} = ammo_group_fixture(shotgun_type, container, current_user)
      pistol_type = ammo_type_fixture(%{type: "pistol"}, current_user)
      {1, [pistol_ammo_group]} = ammo_group_fixture(pistol_type, container, current_user)

      {:ok, index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "All"

      assert html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_type"]/)
        |> render_change(ammo_type: %{type: :rifle})

      assert html =~ rifle_ammo_group.ammo_type.name
      refute html =~ shotgun_ammo_group.ammo_type.name
      refute html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_type"]/)
        |> render_change(ammo_type: %{type: :shotgun})

      refute html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      refute html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_type"]/)
        |> render_change(ammo_type: %{type: :pistol})

      refute html =~ rifle_ammo_group.ammo_type.name
      refute html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name

      html =
        index_live
        |> form(~s/form[phx-change="change_type"]/)
        |> render_change(ammo_type: %{type: :all})

      assert html =~ rifle_ammo_group.ammo_type.name
      assert html =~ shotgun_ammo_group.ammo_type.name
      assert html =~ pistol_ammo_group.ammo_type.name
    end

    test "can search for ammo_groups", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      ammo_group = ammo_group |> Repo.preload(:ammo_type)

      assert html =~ ammo_group.ammo_type.name

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ammo_group.ammo_type.name}) =~
               ammo_group.ammo_type.name

      assert_patch(
        index_live,
        Routes.ammo_group_index_path(conn, :search, ammo_group.ammo_type.name)
      )

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~
               ammo_group.ammo_type.name

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ ammo_group.ammo_type.name

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :index))
    end

    test "saves a single new ammo_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit(ammo_group: @create_attrs)
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n42\n"
    end

    test "saves multiple new ammo_groups", %{conn: conn, current_user: current_user} do
      multiplier = 25
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit(ammo_group: @create_attrs |> Map.put(:multiplier, multiplier))
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert Ammo.list_ammo_groups(nil, :all, current_user) |> Enum.count() == multiplier + 1
    end

    test "does not save invalid number of new ammo_groups", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.ammo_group_index_path(conn, :new))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      assert index_live
             |> form("#ammo_group-form")
             |> render_submit(ammo_group: @create_attrs |> Map.put(:multiplier, "0")) =~
               "Invalid number of copies, must be between 1 and #{@ammo_group_create_limit}. Was 0"

      assert index_live
             |> form("#ammo_group-form")
             |> render_submit(
               ammo_group: @create_attrs |> Map.put(:multiplier, @ammo_group_create_limit + 1)
             ) =~
               "Invalid number of copies, must be between 1 and #{@ammo_group_create_limit}. Was #{@ammo_group_create_limit + 1}"
    end

    test "updates ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Edit ammo group of #{ammo_group.count} bullets"]/)
             |> render_click() =~ "Edit ammo"

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :edit, ammo_group))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit(ammo_group: @update_attrs)
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo updated successfully"
      assert html =~ "\n43\n"
    end

    test "clones ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone ammo group of #{ammo_group.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :clone, ammo_group))

      {:ok, _index_live, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit()
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n42\n"
      assert html =~ "$#{display_currency(120.5)}"
    end

    test "checks validity when cloning", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone ammo group of #{ammo_group.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"

      assert_patch(index_live, Routes.ammo_group_index_path(conn, :clone, ammo_group))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"
    end

    test "clones ammo_group in listing with updates", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone ammo group of #{ammo_group.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"
      assert_patch(index_live, Routes.ammo_group_index_path(conn, :clone, ammo_group))

      assert index_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#ammo_group-form")
        |> render_submit(ammo_group: @create_attrs |> Map.put(:count, 43))
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n43\n"
      assert html =~ "$#{display_currency(120.5)}"
    end

    test "deletes ammo_group in listing", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Delete ammo group of #{ammo_group.count} bullets"]/)
             |> render_click()

      refute has_element?(index_live, "#ammo_group-#{ammo_group.id}")
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.ammo_group_index_path(conn, :add_shot_group, ammo_group))

      assert index_live
             |> form("#shot-group-form")
             |> render_change(shot_group: @shot_group_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form")
        |> render_submit(shot_group: @shot_group_create_attrs)
        |> follow_redirect(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Shots recorded successfully"
    end

    @spec display_currency(float()) :: String.t()
    defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
  end

  describe "Index of empty ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group, :create_empty_ammo_group]

    test "hides empty ammo groups by default", %{
      conn: conn,
      empty_ammo_group: ammo_group,
      current_user: current_user
    } do
      {:ok, show_live, html} = live(conn, Routes.ammo_group_index_path(conn, :index))

      assert html =~ "Show used"
      refute html =~ "$#{display_currency(50.00)}"

      percentage = ammo_group |> Ammo.get_percentage_remaining(current_user)
      refute html =~ "\n#{"#{percentage}%"}\n"

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "$#{display_currency(50.00)}"
      percentage = ammo_group |> Ammo.get_percentage_remaining(current_user)
      assert html =~ "\n#{"#{percentage}%"}\n"
    end
  end

  describe "Show ammo group" do
    setup [:register_and_log_in_user, :create_ammo_group]

    test "displays ammo_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, _show_live, html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))
      ammo_group = ammo_group |> Repo.preload(:ammo_type)
      assert html =~ "Show Ammo"
      assert html =~ ammo_group.ammo_type.name
    end

    test "updates ammo_group within modal", %{conn: conn, ammo_group: ammo_group} do
      {:ok, show_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert show_live
             |> element(~s/a[aria-label="Edit ammo group of #{ammo_group.count} bullets"]/)
             |> render_click() =~ "Edit Ammo"

      assert_patch(show_live, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      assert show_live
             |> form("#ammo_group-form")
             |> render_change(ammo_group: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#ammo_group-form")
        |> render_submit(ammo_group: @update_attrs)
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ "Ammo updated successfully"
      assert html =~ "some updated notes"
    end

    test "saves new shot_group", %{conn: conn, ammo_group: ammo_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.ammo_group_show_path(conn, :add_shot_group, ammo_group))

      assert index_live
             |> form("#shot-group-form")
             |> render_change(shot_group: @shot_group_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form")
        |> render_submit(shot_group: @shot_group_create_attrs)
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ "Shots recorded successfully"
    end
  end

  describe "Show ammo group with shot group" do
    setup [:register_and_log_in_user, :create_ammo_group, :create_shot_group]

    test "updates shot_group in listing",
         %{conn: conn, ammo_group: ammo_group, shot_group: shot_group} do
      {:ok, index_live, _html} = live(conn, Routes.ammo_group_show_path(conn, :edit, ammo_group))

      assert index_live
             |> element(~s/a[aria-label="Edit shot group of #{shot_group.count} shots"]/)
             |> render_click() =~ "Edit Shot Records"

      assert_patch(
        index_live,
        Routes.ammo_group_show_path(conn, :edit_shot_group, ammo_group, shot_group)
      )

      assert index_live
             |> form("#shot-group-form")
             |> render_change(shot_group: @shot_group_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-group-form")
        |> render_submit(shot_group: @shot_group_update_attrs)
        |> follow_redirect(conn, Routes.ammo_group_show_path(conn, :show, ammo_group))

      assert html =~ "Shot records updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes shot_group in listing",
         %{conn: conn, ammo_group: ammo_group, shot_group: shot_group} do
      {:ok, index_live, _html} =
        live(conn, Routes.ammo_group_show_path(conn, :edit_shot_group, ammo_group, shot_group))

      assert index_live
             |> element(~s/a[aria-label="Delete shot record of #{shot_group.count} shots"]/)
             |> render_click()

      refute has_element?(index_live, "#shot_group-#{shot_group.id}")
    end
  end
end
