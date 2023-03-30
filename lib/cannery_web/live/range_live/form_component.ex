defmodule CanneryWeb.RangeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update a ShotGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, ActivityLog, ActivityLog.ShotGroup, Ammo, Ammo.Pack}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(socket), do: {:ok, socket |> assign(:pack, nil)}

  @impl true
  @spec update(
          %{
            required(:shot_group) => ShotGroup.t(),
            required(:current_user) => User.t(),
            optional(:pack) => Pack.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{
          shot_group: %ShotGroup{pack_id: pack_id},
          current_user: current_user
        } = assigns,
        socket
      )
      when is_binary(pack_id) do
    pack = Ammo.get_pack!(pack_id, current_user)
    {:ok, socket |> assign(assigns) |> assign(:pack, pack) |> assign_changeset(%{})}
  end

  def update(%{shot_group: %ShotGroup{}} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"shot_group" => shot_group_params}, socket) do
    {:noreply, socket |> assign_changeset(shot_group_params, :validate)}
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

  defp assign_changeset(
         %{
           assigns: %{
             action: live_action,
             current_user: user,
             pack: pack,
             shot_group: shot_group
           }
         } = socket,
         shot_group_params,
         action \\ nil
       ) do
    default_action =
      case live_action do
        :add_shot_group -> :insert
        editing when editing in [:edit, :edit_shot_group] -> :update
      end

    changeset =
      case default_action do
        :insert -> shot_group |> ShotGroup.create_changeset(user, pack, shot_group_params)
        :update -> shot_group |> ShotGroup.update_changeset(user, shot_group_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(action || default_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(:changeset, changeset)
  end
end
