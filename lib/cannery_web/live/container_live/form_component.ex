defmodule CanneryWeb.ContainerLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Containers.Container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Containers, Containers.Container}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:container => Container.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{container: container} = assigns, socket) do
    changeset = container |> Container.update_changeset(%{})
    {:ok, socket |> assign(assigns) |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"container" => container_params},
        %{assigns: %{container: container}} = socket
      ) do
    changeset = container |> Container.update_changeset(container_params)
    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"container" => container_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_container(socket, action, container_params)
  end

  defp save_container(
         %{assigns: %{container: container, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         container_params
       ) do
    socket =
      case Containers.update_container(container, current_user, container_params) do
        {:ok, %{name: container_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: container_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_container(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         container_params
       ) do
    socket =
      case Containers.create_container(container_params, current_user) do
        {:ok, %{name: container_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: container_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
