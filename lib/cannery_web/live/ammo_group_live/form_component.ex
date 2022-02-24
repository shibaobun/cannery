defmodule CanneryWeb.AmmoGroupLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoGroup
  """

  use CanneryWeb, :live_component
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Cannery.{Accounts.User, Ammo, Containers, Containers.Container}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @ammo_group_create_limit 10_000

  @impl true
  @spec update(
          %{:ammo_group => AmmoGroup.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{ammo_group: _ammo_group} = assigns, socket) do
    socket |> assign(assigns) |> update()
  end

  @spec update(Socket.t()) :: {:ok, Socket.t()}
  def update(%{assigns: %{ammo_group: ammo_group, current_user: current_user}} = socket) do
    socket =
      socket
      |> assign(:ammo_group_create_limit, @ammo_group_create_limit)
      |> assign(:changeset, Ammo.change_ammo_group(ammo_group))
      |> assign(:ammo_types, Ammo.list_ammo_types(current_user))
      |> assign_new(:containers, fn -> Containers.list_containers(current_user) end)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"ammo_group" => ammo_group_params},
        %{assigns: %{ammo_group: ammo_group}} = socket
      ) do
    socket = socket |> assign(:changeset, ammo_group |> Ammo.change_ammo_group(ammo_group_params))
    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{"ammo_group" => ammo_group_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_ammo_group(socket, action, ammo_group_params)
  end

  # HTML Helpers
  @spec container_options([Container.t()]) :: [{String.t(), Container.id()}]
  defp container_options(containers) do
    containers |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  @spec ammo_type_options([AmmoType.t()]) :: [{String.t(), AmmoType.id()}]
  defp ammo_type_options(ammo_types) do
    ammo_types |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
  end

  # Save Helpers

  defp save_ammo_group(
         %{assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         ammo_group_params
       ) do
    socket =
      case Ammo.update_ammo_group(ammo_group, ammo_group_params, current_user) do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo group updated successfully")
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_ammo_group(
         %{assigns: %{changeset: changeset}} = socket,
         :new,
         %{"multiplier" => multiplier_str} = ammo_group_params
       ) do
    socket =
      case multiplier_str |> Integer.parse() do
        {multiplier, _remainder}
        when multiplier >= 1 and multiplier <= @ammo_group_create_limit ->
          socket |> create_multiple(ammo_group_params, multiplier)

        {multiplier, _remainder} ->
          error_msg =
            dgettext(
              "errors",
              "Invalid number of copies, must be between 1 and %{max}. Was %{multiplier}",
              max: @ammo_group_create_limit,
              multiplier: multiplier
            )

          {:error, changeset} =
            changeset
            |> Changeset.add_error(:multiplier, error_msg)
            |> Changeset.apply_action(:insert)

          socket |> assign(:changeset, changeset)

        :error ->
          error_msg = dgettext("errors", "Could not parse number of copies")

          {:error, changeset} =
            changeset
            |> Changeset.add_error(:multiplier, error_msg)
            |> Changeset.apply_action(:insert)

          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp create_multiple(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         ammo_group_params,
         multiplier
       ) do
    case Ammo.create_ammo_groups(ammo_group_params, multiplier, current_user) do
      {:ok, {count, _ammo_groups}} ->
        prompt =
          dngettext(
            "prompts",
            "Ammo group created successfully",
            "Ammo groups created successfully",
            count
          )

        socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

      {:error, %Changeset{} = changeset} ->
        socket |> assign(changeset: changeset)

      {:error, nil} ->
        socket
    end
  end
end
