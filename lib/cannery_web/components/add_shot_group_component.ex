defmodule CanneryWeb.Components.AddShotRecordComponent do
  @moduledoc """
  Livecomponent that can create a ShotRecord
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, ActivityLog.ShotRecord, Ammo.Pack}
  alias Ecto.Changeset
  alias Phoenix.LiveView.{JS, Socket}

  @impl true
  @spec update(
          %{
            required(:current_user) => User.t(),
            required(:pack) => Pack.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{pack: pack, current_user: current_user} = assigns, socket) do
    changeset =
      %ShotRecord{date: Date.utc_today()}
      |> ShotRecord.create_changeset(current_user, pack, %{})

    {:ok, socket |> assign(assigns) |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"shot_record" => shot_record_params},
        %{assigns: %{pack: pack, current_user: current_user}} = socket
      ) do
    params = shot_record_params |> process_params(pack)

    changeset = %ShotRecord{} |> ShotRecord.create_changeset(current_user, pack, params)

    changeset =
      case changeset |> Changeset.apply_action(:validate) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"shot_record" => shot_record_params},
        %{
          assigns: %{pack: pack, current_user: current_user, return_to: return_to}
        } = socket
      ) do
    socket =
      shot_record_params
      |> process_params(pack)
      |> ActivityLog.create_shot_record(current_user, pack)
      |> case do
        {:ok, _shot_record} ->
          prompt = dgettext("prompts", "Shots recorded successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  # calculate count from shots left
  defp process_params(params, %Pack{count: count}) do
    shot_record_count =
      if params |> Map.get("ammo_left", "") == "" do
        nil
      else
        new_count = params |> Map.get("ammo_left") |> String.to_integer()
        count - new_count
      end

    params |> Map.put("count", shot_record_count)
  end
end
