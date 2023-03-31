defmodule CanneryWeb.PackLiveTest do
  @moduledoc """
  Tests pack live pages
  """

  use CanneryWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Cannery.{Ammo, Repo}

  @moduletag :pack_live_test
  @create_attrs %{count: 42, notes: "some notes", price_paid: 120.5}
  @update_attrs %{count: 43, notes: "some updated notes", price_paid: 456.7}
  @invalid_attrs %{count: nil, notes: nil, price_paid: nil}
  @pack_create_limit 10_000
  @shot_record_create_attrs %{ammo_left: 5, notes: "some notes"}
  @shot_record_update_attrs %{
    count: 5,
    date: ~N[2022-02-13 03:17:00],
    notes: "some updated notes"
  }
  @shot_record_invalid_attrs %{ammo_left: nil, count: nil, notes: nil}
  @empty_attrs %{
    price_paid: 50,
    count: 20
  }
  @shot_record_attrs %{
    price_paid: 50,
    count: 20
  }

  defp create_pack(%{current_user: current_user}) do
    type = type_fixture(current_user)
    container = container_fixture(current_user)
    {1, [pack]} = pack_fixture(@create_attrs, type, container, current_user)
    [type: type, pack: pack, container: container]
  end

  defp create_shot_record(%{current_user: current_user, pack: pack}) do
    shot_record = shot_record_fixture(@shot_record_update_attrs, current_user, pack)
    pack = pack |> Repo.reload!()
    [pack: pack, shot_record: shot_record]
  end

  defp create_empty_pack(%{
         current_user: current_user,
         type: type,
         container: container
       }) do
    {1, [pack]} = pack_fixture(@empty_attrs, type, container, current_user)
    shot_record = shot_record_fixture(@shot_record_attrs, current_user, pack)
    pack = pack |> Repo.reload!()
    [empty_pack: pack, shot_record: shot_record]
  end

  describe "Index of pack" do
    setup [:register_and_log_in_user, :create_pack]

    test "lists all packs", %{conn: conn, pack: pack} do
      {:ok, _index_live, html} = live(conn, Routes.pack_index_path(conn, :index))
      pack = pack |> Repo.preload(:type)
      assert html =~ "Ammo"
      assert html =~ pack.type.name
    end

    test "can sort by type",
         %{conn: conn, container: container, current_user: current_user} do
      rifle_type = type_fixture(%{class: :rifle}, current_user)
      {1, [rifle_pack]} = pack_fixture(rifle_type, container, current_user)
      shotgun_type = type_fixture(%{class: :shotgun}, current_user)
      {1, [shotgun_pack]} = pack_fixture(shotgun_type, container, current_user)
      pistol_type = type_fixture(%{class: :pistol}, current_user)
      {1, [pistol_pack]} = pack_fixture(pistol_type, container, current_user)

      {:ok, index_live, html} = live(conn, Routes.pack_index_path(conn, :index))

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

    test "can search for packs", %{conn: conn, pack: pack} do
      {:ok, index_live, html} = live(conn, Routes.pack_index_path(conn, :index))

      pack = pack |> Repo.preload(:type)

      assert html =~ pack.type.name

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: pack.type.name}) =~
               pack.type.name

      assert_patch(
        index_live,
        Routes.pack_index_path(conn, :search, pack.type.name)
      )

      refute index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: "something_else"}) =~
               pack.type.name

      assert_patch(index_live, Routes.pack_index_path(conn, :search, "something_else"))

      assert index_live
             |> form(~s/form[phx-change="search"]/)
             |> render_change(search: %{search_term: ""}) =~ pack.type.name

      assert_patch(index_live, Routes.pack_index_path(conn, :index))
    end

    test "saves a single new pack", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.pack_index_path(conn, :new))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#pack-form")
        |> render_submit(pack: @create_attrs)
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n42\n"
    end

    test "saves multiple new packs", %{conn: conn, current_user: current_user} do
      multiplier = 25
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.pack_index_path(conn, :new))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#pack-form")
        |> render_submit(pack: @create_attrs |> Map.put(:multiplier, multiplier))
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert Ammo.list_packs(nil, :all, current_user) |> Enum.count() == multiplier + 1
    end

    test "does not save invalid number of new packs", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live |> element("a", "Add Ammo") |> render_click() =~ "Add Ammo"
      assert_patch(index_live, Routes.pack_index_path(conn, :new))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      assert index_live
             |> form("#pack-form")
             |> render_submit(pack: @create_attrs |> Map.put(:multiplier, "0")) =~
               "Invalid number of copies, must be between 1 and #{@pack_create_limit}. Was 0"

      assert index_live
             |> form("#pack-form")
             |> render_submit(pack: @create_attrs |> Map.put(:multiplier, @pack_create_limit + 1)) =~
               "Invalid number of copies, must be between 1 and #{@pack_create_limit}. Was #{@pack_create_limit + 1}"
    end

    test "updates pack in listing", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Edit pack of #{pack.count} bullets"]/)
             |> render_click() =~ "Edit ammo"

      assert_patch(index_live, Routes.pack_index_path(conn, :edit, pack))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#pack-form")
        |> render_submit(pack: @update_attrs)
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Ammo updated successfully"
      assert html =~ "\n43\n"
    end

    test "clones pack in listing", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone pack of #{pack.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"

      assert_patch(index_live, Routes.pack_index_path(conn, :clone, pack))

      {:ok, _index_live, html} =
        index_live
        |> form("#pack-form")
        |> render_submit()
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n42\n"
      assert html =~ "$#{display_currency(120.5)}"
    end

    test "checks validity when cloning", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone pack of #{pack.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"

      assert_patch(index_live, Routes.pack_index_path(conn, :clone, pack))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"
    end

    test "clones pack in listing with updates", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      html =
        index_live
        |> element(~s/a[aria-label="Clone pack of #{pack.count} bullets"]/)
        |> render_click()

      assert html =~ "Add Ammo"
      assert html =~ "$#{display_currency(120.5)}"
      assert_patch(index_live, Routes.pack_index_path(conn, :clone, pack))

      assert index_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#pack-form")
        |> render_submit(pack: @create_attrs |> Map.put(:count, 43))
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Ammo added successfully"
      assert html =~ "\n43\n"
      assert html =~ "$#{display_currency(120.5)}"
    end

    test "deletes pack in listing", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live
             |> element(~s/a[aria-label="Delete pack of #{pack.count} bullets"]/)
             |> render_click()

      refute has_element?(index_live, "#pack-#{pack.id}")
    end

    test "saves new shot_record", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_index_path(conn, :index))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.pack_index_path(conn, :add_shot_record, pack))

      assert index_live
             |> form("#shot-record-form")
             |> render_change(shot_record: @shot_record_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-record-form")
        |> render_submit(shot_record: @shot_record_create_attrs)
        |> follow_redirect(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Shots recorded successfully"
    end

    @spec display_currency(float()) :: String.t()
    defp display_currency(float), do: :erlang.float_to_binary(float, decimals: 2)
  end

  describe "Index of empty pack" do
    setup [:register_and_log_in_user, :create_pack, :create_empty_pack]

    test "hides empty packs by default", %{
      conn: conn,
      empty_pack: pack,
      current_user: current_user
    } do
      {:ok, show_live, html} = live(conn, Routes.pack_index_path(conn, :index))

      assert html =~ "Show used"
      refute html =~ "$#{display_currency(50.00)}"

      percentage = pack |> Ammo.get_percentage_remaining(current_user)
      refute html =~ "\n#{"#{percentage}%"}\n"

      html =
        show_live
        |> element(~s/input[type="checkbox"][aria-labelledby="toggle_show_used-label"}]/)
        |> render_click()

      assert html =~ "$#{display_currency(50.00)}"
      percentage = pack |> Ammo.get_percentage_remaining(current_user)
      assert html =~ "\n#{"#{percentage}%"}\n"
    end
  end

  describe "Show pack" do
    setup [:register_and_log_in_user, :create_pack]

    test "displays pack", %{conn: conn, pack: pack} do
      {:ok, _show_live, html} = live(conn, Routes.pack_show_path(conn, :show, pack))
      pack = pack |> Repo.preload(:type)
      assert html =~ "Show Ammo"
      assert html =~ pack.type.name
    end

    test "updates pack within modal", %{conn: conn, pack: pack} do
      {:ok, show_live, _html} = live(conn, Routes.pack_show_path(conn, :show, pack))

      assert show_live
             |> element(~s/a[aria-label="Edit pack of #{pack.count} bullets"]/)
             |> render_click() =~ "Edit Ammo"

      assert_patch(show_live, Routes.pack_show_path(conn, :edit, pack))

      assert show_live
             |> form("#pack-form")
             |> render_change(pack: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        show_live
        |> form("#pack-form")
        |> render_submit(pack: @update_attrs)
        |> follow_redirect(conn, Routes.pack_show_path(conn, :show, pack))

      assert html =~ "Ammo updated successfully"
      assert html =~ "some updated notes"
    end

    test "saves new shot_record", %{conn: conn, pack: pack} do
      {:ok, index_live, _html} = live(conn, Routes.pack_show_path(conn, :show, pack))

      assert index_live |> element("a", "Record shots") |> render_click() =~ "Record shots"
      assert_patch(index_live, Routes.pack_show_path(conn, :add_shot_record, pack))

      assert index_live
             |> form("#shot-record-form")
             |> render_change(shot_record: @shot_record_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-record-form")
        |> render_submit(shot_record: @shot_record_create_attrs)
        |> follow_redirect(conn, Routes.pack_show_path(conn, :show, pack))

      assert html =~ "Shots recorded successfully"
    end
  end

  describe "Show pack with shot recorddd" do
    setup [:register_and_log_in_user, :create_pack, :create_shot_record]

    test "updates shot_record in listing",
         %{conn: conn, pack: pack, shot_record: shot_record} do
      {:ok, index_live, _html} = live(conn, Routes.pack_show_path(conn, :edit, pack))

      assert index_live
             |> element(~s/a[aria-label="Edit shot recordd of #{shot_record.count} shots"]/)
             |> render_click() =~ "Edit Shot Record"

      assert_patch(
        index_live,
        Routes.pack_show_path(conn, :edit_shot_record, pack, shot_record)
      )

      assert index_live
             |> form("#shot-record-form")
             |> render_change(shot_record: @shot_record_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _view, html} =
        index_live
        |> form("#shot-record-form")
        |> render_submit(shot_record: @shot_record_update_attrs)
        |> follow_redirect(conn, Routes.pack_show_path(conn, :show, pack))

      assert html =~ "Shot records updated successfully"
      assert html =~ "some updated notes"
    end

    test "deletes shot_record in listing",
         %{conn: conn, pack: pack, shot_record: shot_record} do
      {:ok, index_live, _html} =
        live(conn, Routes.pack_show_path(conn, :edit_shot_record, pack, shot_record))

      assert index_live
             |> element(~s/a[aria-label="Delete shot record of #{shot_record.count} shots"]/)
             |> render_click()

      refute has_element?(index_live, "#shot_record-#{shot_record.id}")
    end
  end
end
