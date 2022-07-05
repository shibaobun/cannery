defmodule CanneryWeb.AmmoTypeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoType}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:ammo_type => AmmoType.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{current_user: _current_user} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"ammo_type" => ammo_type_params}, socket) do
    {:noreply, socket |> assign_changeset(ammo_type_params)}
  end

  def handle_event(
        "save",
        %{"ammo_type" => ammo_type_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_ammo_type(socket, action, ammo_type_params)
  end

  defp assign_changeset(
         %{assigns: %{action: action, ammo_type: ammo_type, current_user: user}} = socket,
         ammo_type_params
       ) do
    changeset_action =
      case action do
        :new -> :insert
        :edit -> :update
      end

    changeset =
      case action do
        :new -> ammo_type |> AmmoType.create_changeset(user, ammo_type_params)
        :edit -> ammo_type |> AmmoType.update_changeset(ammo_type_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(changeset_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(changeset: changeset)
  end

  defp save_ammo_type(
         %{assigns: %{ammo_type: ammo_type, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         ammo_type_params
       ) do
    socket =
      case Ammo.update_ammo_type(ammo_type, ammo_type_params, current_user) do
        {:ok, %{name: ammo_type_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: ammo_type_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_ammo_type(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         ammo_type_params
       ) do
    socket =
      case Ammo.create_ammo_type(ammo_type_params, current_user) do
        {:ok, %{name: ammo_type_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: ammo_type_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
