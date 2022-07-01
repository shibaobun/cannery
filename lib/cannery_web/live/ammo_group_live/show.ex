defmodule CanneryWeb.AmmoGroupLive.Show do
  @moduledoc """
  Liveview for showing and editing an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.ContainerCard
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup, Ammo, Ammo.AmmoGroup, Repo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(
        %{"id" => id, "shot_group_id" => shot_group_id},
        _url,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    shot_group = ActivityLog.get_shot_group!(shot_group_id, current_user)

    socket =
      socket
      |> assign(page_title: page_title(live_action), shot_group: shot_group)
      |> display_ammo_group(id)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, socket |> assign(page_title: page_title(live_action)) |> display_ammo_group(id)}
  end

  defp page_title(:add_shot_group), do: gettext("Record Shots")
  defp page_title(:edit_shot_group), do: gettext("Edit Shot Records")
  defp page_title(:move), do: gettext("Move Ammo")
  defp page_title(:show), do: gettext("Show Ammo")
  defp page_title(:edit), do: gettext("Edit Ammo")

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    ammo_group |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo deleted succesfully")
    redirect_to = Routes.ammo_group_index_path(socket, :index)

    {:noreply, socket |> put_flash(:info, prompt) |> push_redirect(to: redirect_to)}
  end

  @impl true
  def handle_event(
        "toggle_staged",
        _params,
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    {:ok, ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> display_ammo_group(ammo_group)}
  end

  @impl true
  def handle_event(
        "delete_shot_group",
        %{"id" => id},
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    {:ok, _} =
      ActivityLog.get_shot_group!(id, current_user)
      |> ActivityLog.delete_shot_group(current_user)

    prompt = dgettext("prompts", "Shot records deleted succesfully")
    {:noreply, socket |> put_flash(:info, prompt) |> display_ammo_group(ammo_group)}
  end

  @spec display_ammo_group(Socket.t(), AmmoGroup.t() | AmmoGroup.id()) :: Socket.t()
  defp display_ammo_group(socket, %AmmoGroup{} = ammo_group) do
    ammo_group = ammo_group |> Repo.preload([:container, :ammo_type, :shot_groups], force: true)

    columns = [
      %{label: gettext("Rounds shot"), key: "count"},
      %{label: gettext("Notes"), key: "notes"},
      %{label: gettext("Date"), key: "date"},
      %{label: nil, key: "actions", sortable: false}
    ]

    rows =
      ammo_group.shot_groups
      |> Enum.map(fn shot_group ->
        ammo_group |> get_table_row_for_shot_group(shot_group, columns)
      end)

    socket |> assign(ammo_group: ammo_group, columns: columns, rows: rows)
  end

  defp display_ammo_group(%{assigns: %{current_user: current_user}} = socket, id),
    do: display_ammo_group(socket, Ammo.get_ammo_group!(id, current_user))

  @spec get_table_row_for_shot_group(AmmoGroup.t(), ShotGroup.t(), [map()]) :: [map()]
  defp get_table_row_for_shot_group(ammo_group, %{date: date} = shot_group, columns) do
    assigns = %{ammo_group: ammo_group, shot_group: shot_group}

    columns
    |> Enum.into(%{}, fn %{key: key} ->
      value =
        case key do
          "date" ->
            {date, date |> display_date()}

          "actions" ->
            ~H"""
            <div class="px-4 py-2 space-x-4 flex justify-center items-center">
              <%= live_patch to: Routes.ammo_group_show_path(Endpoint, :edit_shot_group, @ammo_group, shot_group),
                          class: "text-primary-600 link",
                          data: [qa: "edit-#{shot_group.id}"] do %>
                <i class="fa-fw fa-lg fas fa-edit"></i>
              <% end %>

              <%= link to: "#",
                    class: "text-primary-600 link",
                    phx_click: "delete_shot_group",
                    phx_value_id: shot_group.id,
                    data: [
                      confirm: dgettext("prompts", "Are you sure you want to delete this shot record?"),
                      qa: "delete-#{shot_group.id}"
                    ] do %>
                <i class="fa-fw fa-lg fas fa-trash"></i>
              <% end %>
            </div>
            """

          key ->
            shot_group |> Map.get(key |> String.to_existing_atom())
        end

      {key, value}
    end)
  end
end
