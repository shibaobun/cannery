defmodule CanneryWeb.RangeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update a ShotRecord
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, ActivityLog.ShotRecord, Ammo, Ammo.Pack}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(socket), do: {:ok, socket |> assign(:pack, nil)}

  @impl true
  @spec update(
          %{
            required(:shot_record) => ShotRecord.t(),
            required(:current_user) => User.t(),
            optional(:pack) => Pack.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{
          shot_record: %ShotRecord{pack_id: pack_id},
          current_user: current_user
        } = assigns,
        socket
      )
      when is_binary(pack_id) do
    pack = Ammo.get_pack!(pack_id, current_user)
    {:ok, socket |> assign(assigns) |> assign(:pack, pack) |> assign_changeset(%{})}
  end

  def update(%{shot_record: %ShotRecord{}} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"shot_record" => shot_record_params}, socket) do
    {:noreply, socket |> assign_changeset(shot_record_params, :validate)}
  end

  def handle_event(
        "save",
        %{"shot_record" => shot_record_params},
        %{assigns: %{shot_record: shot_record, current_user: current_user, return_to: return_to}} =
          socket
      ) do
    socket =
      case ActivityLog.update_shot_record(shot_record, shot_record_params, current_user) do
        {:ok, _shot_record} ->
          prompt = dgettext("prompts", "Shot records updated successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp assign_changeset(
         %{
           assigns: %{
             action: live_action,
             current_user: user,
             pack: pack,
             shot_record: shot_record
           }
         } = socket,
         shot_record_params,
         action \\ nil
       ) do
    default_action =
      case live_action do
        :add_shot_record -> :insert
        editing when editing in [:edit, :edit_shot_record] -> :update
      end

    changeset =
      case default_action do
        :insert -> shot_record |> ShotRecord.create_changeset(user, pack, shot_record_params)
        :update -> shot_record |> ShotRecord.update_changeset(user, shot_record_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(action || default_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(:changeset, changeset)
  end
end
