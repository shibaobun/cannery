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
  def update(%{assigns: %{current_user: current_user}} = socket) do
    %{assigns: %{ammo_types: ammo_types, containers: containers}} =
      socket =
      socket
      |> assign(:ammo_group_create_limit, @ammo_group_create_limit)
      |> assign(:ammo_types, Ammo.list_ammo_types(current_user, :all))
      |> assign_new(:containers, fn -> Containers.list_containers(current_user) end)

    params =
      if ammo_types |> List.first() |> is_nil(),
        do: %{},
        else: %{} |> Map.put("ammo_type_id", ammo_types |> List.first() |> Map.get(:id))

    params =
      if containers |> List.first() |> is_nil(),
        do: params,
        else: params |> Map.put("container_id", containers |> List.first() |> Map.get(:id))

    {:ok, socket |> assign_changeset(params)}
  end

  @impl true
  def handle_event("validate", %{"ammo_group" => ammo_group_params}, socket) do
    {:noreply, socket |> assign_changeset(ammo_group_params, :validate)}
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

  defp assign_changeset(
         %{assigns: %{action: action, ammo_group: ammo_group, current_user: user}} = socket,
         ammo_group_params,
         changeset_action \\ nil
       ) do
    default_action =
      case action do
        create when create in [:new, :clone] -> :insert
        :edit -> :update
      end

    changeset =
      case default_action do
        :insert ->
          ammo_type = maybe_get_ammo_type(ammo_group_params, user)
          container = maybe_get_container(ammo_group_params, user)
          ammo_group |> AmmoGroup.create_changeset(ammo_type, container, user, ammo_group_params)

        :update ->
          ammo_group |> AmmoGroup.update_changeset(ammo_group_params, user)
      end

    changeset =
      case changeset |> Changeset.apply_action(changeset_action || default_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(:changeset, changeset)
  end

  defp maybe_get_container(%{"container_id" => container_id}, user)
       when is_binary(container_id) do
    container_id |> Containers.get_container!(user)
  end

  defp maybe_get_container(_params_not_found, _user), do: nil

  defp maybe_get_ammo_type(%{"ammo_type_id" => ammo_type_id}, user)
       when is_binary(ammo_type_id) do
    ammo_type_id |> Ammo.get_ammo_type!(user)
  end

  defp maybe_get_ammo_type(_params_not_found, _user), do: nil

  defp save_ammo_group(
         %{assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         ammo_group_params
       ) do
    socket =
      case Ammo.update_ammo_group(ammo_group, ammo_group_params, current_user) do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo updated successfully")
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_ammo_group(
         %{assigns: %{changeset: changeset}} = socket,
         action,
         %{"multiplier" => multiplier_str} = ammo_group_params
       )
       when action in [:new, :clone] do
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

          save_multiplier_error(socket, changeset, error_msg)

        :error ->
          error_msg = dgettext("errors", "Could not parse number of copies")
          save_multiplier_error(socket, changeset, error_msg)
      end

    {:noreply, socket}
  end

  @spec save_multiplier_error(Socket.t(), Changeset.t(), String.t()) :: Socket.t()
  defp save_multiplier_error(socket, changeset, error_msg) do
    {:error, changeset} =
      changeset
      |> Changeset.add_error(:multiplier, error_msg)
      |> Changeset.apply_action(:insert)

    socket |> assign(:changeset, changeset)
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
            "Ammo added successfully",
            "Ammo added successfully",
            count
          )

        socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

      {:error, %Changeset{} = changeset} ->
        socket |> assign(changeset: changeset)
    end
  end
end
