defmodule CanneryWeb.RangeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update a ShotGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, ActivityLog.ShotGroup, Ammo, Ammo.AmmoGroup}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{
            required(:shot_group) => ShotGroup.t(),
            required(:current_user) => User.t(),
            optional(:ammo_group) => AmmoGroup.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{
          shot_group: %ShotGroup{ammo_group_id: ammo_group_id} = shot_group,
          current_user: current_user
        } = assigns,
        socket
      ) do
    changeset = shot_group |> ShotGroup.update_changeset(current_user, %{})
    ammo_group = Ammo.get_ammo_group!(ammo_group_id, current_user)
    {:ok, socket |> assign(assigns) |> assign(ammo_group: ammo_group, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"shot_group" => shot_group_params},
        %{assigns: %{current_user: current_user, shot_group: shot_group}} = socket
      ) do
    changeset =
      shot_group
      |> ShotGroup.update_changeset(current_user, shot_group_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"shot_group" => shot_group_params},
        %{assigns: %{shot_group: shot_group, current_user: current_user, return_to: return_to}} =
          socket
      ) do
    socket =
      case ActivityLog.update_shot_group(shot_group, shot_group_params, current_user) do
        {:ok, _shot_group} ->
          prompt = dgettext("prompts", "Shot records updated successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end
end
