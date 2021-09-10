defmodule CanneryWeb.InviteLiveTest do
  use CanneryWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Cannery.Invites

  @create_attrs %{name: "some name", token: "some token"}
  @update_attrs %{name: "some updated name", token: "some updated token"}
  @invalid_attrs %{name: nil, token: nil}

  defp fixture(:invite) do
    {:ok, invite} = Invites.create_invite(@create_attrs)
    invite
  end

  defp create_invite(_) do
    invite = fixture(:invite)
    %{invite: invite}
  end

  describe "Index" do
    setup [:create_invite]

    test "lists all invites", %{conn: conn, invite: invite} do
      {:ok, _index_live, html} = live(conn, Routes.invite_index_path(conn, :index))

      assert html =~ "Listing Invites"
      assert html =~ invite.name
    end

    test "saves new invite", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("a", "New Invite") |> render_click() =~
               "New Invite"

      assert_patch(index_live, Routes.invite_index_path(conn, :new))

      assert index_live
             |> form("#invite-form", invite: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#invite-form", invite: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.invite_index_path(conn, :index))

      assert html =~ "Invite created successfully"
      assert html =~ "some name"
    end

    test "updates invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("#invite-#{invite.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert_patch(index_live, Routes.invite_index_path(conn, :edit, invite))

      assert index_live
             |> form("#invite-form", invite: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#invite-form", invite: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.invite_index_path(conn, :index))

      assert html =~ "Invite updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("#invite-#{invite.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#invite-#{invite.id}")
    end
  end

  describe "Show" do
    setup [:create_invite]

    test "displays invite", %{conn: conn, invite: invite} do
      {:ok, _show_live, html} = live(conn, Routes.invite_show_path(conn, :show, invite))

      assert html =~ "Show Invite"
      assert html =~ invite.name
    end

    test "updates invite within modal", %{conn: conn, invite: invite} do
      {:ok, show_live, _html} = live(conn, Routes.invite_show_path(conn, :show, invite))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Invite"

      assert_patch(show_live, Routes.invite_show_path(conn, :edit, invite))

      assert show_live
             |> form("#invite-form", invite: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#invite-form", invite: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.invite_show_path(conn, :show, invite))

      assert html =~ "Invite updated successfully"
      assert html =~ "some updated name"
    end
  end
end
