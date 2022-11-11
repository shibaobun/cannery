defmodule CanneryWeb.AmmoGroupLive.Index do
  @moduledoc """
  Liveview to show a Cannery.Ammo.AmmoGroup index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Ammo, Ammo.AmmoGroup, Containers, Repo}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(show_used: false)}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_ammo_groups()}
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :add_shot_group,
         %{"id" => id}
       ) do
    socket
    |> assign(:page_title, gettext("Record shots"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :move, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Move Ammo group"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Ammo group"))
    |> assign(:ammo_group, Ammo.get_ammo_group!(id, current_user))
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    socket
    |> assign(:page_title, dgettext("actions", "Add Ammo"))
    |> assign(:ammo_group, %{Ammo.get_ammo_group!(id, current_user) | id: nil})
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("actions", "Add Ammo"))
    |> assign(:ammo_group, %AmmoGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Ammo groups"))
    |> assign(:ammo_group, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    Ammo.get_ammo_group!(id, current_user) |> Ammo.delete_ammo_group!(current_user)

    prompt = dgettext("prompts", "Ammo group deleted succesfully")

    {:noreply, socket |> put_flash(:info, prompt) |> display_ammo_groups()}
  end

  @impl true
  def handle_event(
        "toggle_staged",
        %{"ammo_group_id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    ammo_group = Ammo.get_ammo_group!(id, current_user)

    {:ok, _ammo_group} =
      ammo_group |> Ammo.update_ammo_group(%{"staged" => !ammo_group.staged}, current_user)

    {:noreply, socket |> display_ammo_groups()}
  end

  @impl true
  def handle_event("toggle_show_used", _params, %{assigns: %{show_used: show_used}} = socket) do
    {:noreply, socket |> assign(:show_used, !show_used) |> display_ammo_groups()}
  end

  defp display_ammo_groups(
         %{assigns: %{current_user: current_user, show_used: show_used}} = socket
       ) do
    ammo_groups =
      Ammo.list_ammo_groups(current_user, show_used)
      |> Repo.preload([:ammo_type, :container], force: true)

    ammo_types_count = Ammo.get_ammo_types_count!(current_user)
    containers_count = Containers.get_containers_count!(current_user)

    columns = [
      %{label: gettext("Ammo type"), key: :ammo_type},
      %{label: gettext("Count"), key: :count},
      %{label: gettext("Price paid"), key: :price_paid},
      %{label: gettext("% left"), key: :remaining},
      %{label: gettext("Range"), key: :range},
      %{label: gettext("Container"), key: :container},
      %{label: gettext("Added on"), key: :added_on}
    ]

    columns =
      if show_used do
        columns ++ [%{label: gettext("Used up on"), key: :used_up_on}]
      else
        columns
      end

    columns = columns ++ [%{label: nil, key: :actions, sortable: false}]

    rows =
      ammo_groups
      |> Enum.map(fn ammo_group -> ammo_group |> get_row_data_for_ammo_group(columns) end)

    socket
    |> assign(
      ammo_groups: ammo_groups,
      ammo_types_count: ammo_types_count,
      containers_count: containers_count,
      columns: columns,
      rows: rows
    )
  end

  @spec get_row_data_for_ammo_group(AmmoGroup.t(), [map()]) :: [map()]
  defp get_row_data_for_ammo_group(ammo_group, columns) do
    ammo_group = ammo_group |> Repo.preload([:ammo_type, :container])

    columns
    |> Enum.into(%{}, fn %{key: key} -> {key, get_value_for_key(key, ammo_group)} end)
  end

  @spec get_value_for_key(atom(), AmmoGroup.t()) :: any()
  defp get_value_for_key(:ammo_type, %{ammo_type: ammo_type}) do
    assigns = %{ammo_type: ammo_type}

    {ammo_type.name,
     ~H"""
     <.link navigate={Routes.ammo_type_show_path(Endpoint, :show, @ammo_type)} class="link">
       <%= @ammo_type.name %>
     </.link>
     """}
  end

  defp get_value_for_key(:price_paid, %{price_paid: nil}), do: {"a", nil}

  defp get_value_for_key(:price_paid, %{price_paid: price_paid}),
    do: gettext("$%{amount}", amount: price_paid |> :erlang.float_to_binary(decimals: 2))

  defp get_value_for_key(:added_on, %{inserted_at: inserted_at}) do
    assigns = %{inserted_at: inserted_at}

    {inserted_at,
     ~H"""
     <%= @inserted_at |> display_datetime() %>
     """}
  end

  defp get_value_for_key(:used_up_on, ammo_group) do
    last_shot_group_date =
      case ammo_group |> Ammo.get_last_used_shot_group() do
        %{date: last_shot_group_date} -> last_shot_group_date
        _no_shot_groups -> nil
      end

    assigns = %{last_shot_group_date: last_shot_group_date}

    {last_shot_group_date,
     ~H"""
     <%= @last_shot_group_date |> display_date() %>
     """}
  end

  defp get_value_for_key(:range, %{staged: staged} = ammo_group) do
    assigns = %{ammo_group: ammo_group}

    {staged,
     ~H"""
     <div class="min-w-20 py-2 px-4 h-full flex flew-wrap justify-center items-center">
       <button
         type="button"
         class="mx-2 my-1 text-sm btn btn-primary"
         phx-click="toggle_staged"
         phx-value-ammo_group_id={@ammo_group.id}
       >
         <%= if @ammo_group.staged, do: gettext("Unstage"), else: gettext("Stage") %>
       </button>

       <.link
         patch={Routes.ammo_group_index_path(Endpoint, :add_shot_group, @ammo_group)}
         class="mx-2 my-1 text-sm btn btn-primary"
       >
         <%= dgettext("actions", "Record shots") %>
       </.link>
     </div>
     """}
  end

  defp get_value_for_key(:remaining, ammo_group),
    do: gettext("%{percentage}%", percentage: ammo_group |> Ammo.get_percentage_remaining())

  defp get_value_for_key(:actions, ammo_group) do
    assigns = %{ammo_group: ammo_group}

    ~H"""
    <div class="py-2 px-4 h-full space-x-4 flex justify-center items-center">
      <.link
        navigate={Routes.ammo_group_show_path(Endpoint, :show, @ammo_group)}
        class="text-primary-600 link"
        data-qa={"view-#{@ammo_group.id}"}
      >
        <i class="fa-fw fa-lg fas fa-eye"></i>
      </.link>

      <.link
        patch={Routes.ammo_group_index_path(Endpoint, :edit, @ammo_group)}
        class="text-primary-600 link"
        data-qa={"edit-#{@ammo_group.id}"}
      >
        <i class="fa-fw fa-lg fas fa-edit"></i>
      </.link>

      <.link
        patch={Routes.ammo_group_index_path(Endpoint, :clone, @ammo_group)}
        class="text-primary-600 link"
        data-qa={"clone-#{@ammo_group.id}"}
      >
        <i class="fa-fw fa-lg fas fa-copy"></i>
      </.link>

      <.link
        href="#"
        class="text-primary-600 link"
        phx-click="delete"
        phx-value-id={@ammo_group.id}
        data-confirm={dgettext("prompts", "Are you sure you want to delete this ammo?")}
        data-qa={"delete-#{@ammo_group.id}"}
      >
        <i class="fa-fw fa-lg fas fa-trash"></i>
      </.link>
    </div>
    """
  end

  defp get_value_for_key(:container, %{container: nil}), do: {nil, nil}

  defp get_value_for_key(:container, %{container: %{name: container_name}} = ammo_group) do
    assigns = %{ammo_group: ammo_group}

    {container_name,
     ~H"""
     <div class="min-w-20 py-2 px-4 h-full flex flew-wrap justify-center items-center">
       <.link
         navigate={Routes.container_show_path(Endpoint, :show, @ammo_group.container)}
         class="mx-2 my-1 link"
       >
         <%= @ammo_group.container.name %>
       </.link>

       <.link
         patch={Routes.ammo_group_index_path(Endpoint, :move, @ammo_group)}
         class="mx-2 my-1 text-sm btn btn-primary"
       >
         <%= gettext("Move ammo") %>
       </.link>
     </div>
     """}
  end

  defp get_value_for_key(key, ammo_group), do: ammo_group |> Map.get(key)
end
