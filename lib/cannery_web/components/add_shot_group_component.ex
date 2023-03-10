defmodule CanneryWeb.Components.AddShotGroupComponent do
  @moduledoc """
  Livecomponent that can create a ShotGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, ActivityLog.ShotGroup, Ammo.AmmoGroup}
  alias Phoenix.LiveView.{JS, Socket}

  @impl true
  @spec update(
          %{
            required(:current_user) => User.t(),
            required(:ammo_group) => AmmoGroup.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{ammo_group: ammo_group, current_user: current_user} = assigns, socket) do
    changeset =
      %ShotGroup{date: NaiveDateTime.utc_now(), count: 1}
      |> ShotGroup.create_changeset(current_user, ammo_group, %{})

    {:ok, socket |> assign(assigns) |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"shot_group" => shot_group_params},
        %{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket
      ) do
    params = shot_group_params |> process_params(ammo_group)

    changeset =
      %ShotGroup{}
      |> ShotGroup.create_changeset(current_user, ammo_group, params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"shot_group" => shot_group_params},
        %{
          assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}
        } = socket
      ) do
    socket =
      shot_group_params
      |> process_params(ammo_group)
      |> ActivityLog.create_shot_group(current_user, ammo_group)
      |> case do
        {:ok, _shot_group} ->
          prompt = dgettext("prompts", "Shots recorded successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  # calculate count from shots left
  defp process_params(params, %AmmoGroup{count: count}) do
    new_count =
      if params |> Map.get("ammo_left", "0") == "" do
        "0"
      else
        params |> Map.get("ammo_left", "0")
      end
      |> String.to_integer()

    params |> Map.put("count", count - new_count)
  end
end
