defmodule CanneryWeb.TypeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.Type
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.Type}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:type => Type.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{current_user: _current_user} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"type" => type_params}, socket) do
    {:noreply, socket |> assign_changeset(type_params)}
  end

  def handle_event(
        "save",
        %{"type" => type_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_type(socket, action, type_params)
  end

  defp assign_changeset(
         %{assigns: %{action: action, type: type, current_user: user}} = socket,
         type_params
       ) do
    changeset_action =
      case action do
        create when create in [:new, :clone] -> :insert
        :edit -> :update
      end

    changeset =
      case action do
        create when create in [:new, :clone] ->
          type |> Type.create_changeset(user, type_params)

        :edit ->
          type |> Type.update_changeset(type_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(changeset_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(changeset: changeset)
  end

  defp save_type(
         %{assigns: %{type: type, current_user: current_user, return_to: return_to}} = socket,
         :edit,
         type_params
       ) do
    socket =
      case Ammo.update_type(type, type_params, current_user) do
        {:ok, %{name: type_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: type_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_type(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         action,
         type_params
       )
       when action in [:new, :clone] do
    socket =
      case Ammo.create_type(type_params, current_user) do
        {:ok, %{name: type_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: type_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
