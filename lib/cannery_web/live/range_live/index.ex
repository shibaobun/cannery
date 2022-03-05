defmodule CanneryWeb.RangeLive.Index do
  @moduledoc """
  Main page for range day mode, where `AmmoGroup`s can be used up.
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.AmmoGroupCard
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup, Ammo, Repo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign_defaults(session) |> display_shot_groups()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_group,
         %{"id" => id}
       ) do
    socket
    |> assign(:page_title, gettext("Record Shots"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Shot Records"))
    |> assign(:shot_group, ActivityLog.get_shot_group!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Shot Records"))
    |> assign(:shot_group, %ShotGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Shot Records"))
    |> assign(:shot_group, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    {:ok, _} =
      ActivityLog.get_shot_group!(id, current_user)
      |> ActivityLog.delete_shot_group(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_groups()}
  end

  def handle_event(
        "toggle_staged",
        %{"ammo_group_id" => ammo_group_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)

    {:ok, _ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    prompt = dgettext("prompts", "Ammo group unstaged succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_shot_groups()}
  end

  @spec display_shot_groups(Socket.t()) :: Socket.t()
  defp display_shot_groups(%{assigns: %{current_user: current_user}} = socket) do
    shot_groups =
      ActivityLog.list_shot_groups(current_user) |> Repo.preload(ammo_group: :ammo_type)

    ammo_groups = Ammo.list_staged_ammo_groups(current_user)

    columns = [
      %{label: gettext("Ammo"), key: "name"},
      %{label: gettext("Rounds shot"), key: "count"},
      %{label: gettext("Notes"), key: "notes"},
      %{label: gettext("Date"), key: "date"},
      %{label: nil, key: "actions", sortable: false}
    ]

    rows =
      shot_groups
      |> Enum.map(fn %{date: date} = shot_group ->
        assigns = %{shot_group: shot_group}

        columns
        |> Enum.into(%{}, fn %{key: key} ->
          value =
            case key do
              "name" ->
                {shot_group.ammo_group.ammo_type.name,
                 live_patch(shot_group.ammo_group.ammo_type.name,
                   to: Routes.ammo_group_show_path(Endpoint, :show, shot_group.ammo_group),
                   class: "link"
                 )}

              "date" ->
                date |> display_date()

              "actions" ->
                ~H"""
                <div class="px-4 py-2 space-x-4 flex justify-center items-center">
                  <%= live_patch to: Routes.range_index_path(Endpoint, :edit, shot_group),
                             class: "text-primary-600 link",
                             data: [qa: "edit-#{shot_group.id}"] do %>
                    <i class="fa-fw fa-lg fas fa-edit"></i>
                  <% end %>

                  <%= link to: "#",
                       class: "text-primary-600 link",
                       phx_click: "delete",
                       phx_value_id: shot_group.id,
                       data: [
                         confirm: dgettext("prompts", "Are you sure you want to delete this shot record?"),
                         qa: "delete-#{shot_group.id}"
                       ] do %>
                    <i class="fa-fw fa-lg fas fa-trash"></i>
                  <% end %>
                </div>
                """

              value ->
                shot_group |> Map.get(key |> String.to_existing_atom())
            end

          {key, value}
        end)
      end)

    socket
    |> assign(ammo_groups: ammo_groups, columns: columns, rows: rows, shot_groups: shot_groups)
  end
end
