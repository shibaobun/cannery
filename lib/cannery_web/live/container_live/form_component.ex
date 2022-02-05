defmodule CanneryWeb.ContainerLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Containers.Container
  """

  use CanneryWeb, :live_component

  alias Cannery.Containers
  alias Ecto.Changeset

  @impl true
  def update(%{container: container} = assigns, socket) do
    assigns = assigns |> Map.put(:changeset, container |> Containers.change_container())
    {:ok, socket |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", %{"container" => container_params}, socket) do
    container_params = container_params |> Map.put("user_id", socket.assigns.current_user.id)

    changeset =
      socket.assigns.container
      |> Containers.change_container(container_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"container" => container_params}, socket) do
    container_params = container_params |> Map.put("user_id", socket.assigns.current_user.id)
    save_container(socket, socket.assigns.action, container_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-center title text-xl text-primary-500">
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="container-form"
        class="grid grid-cols-3 justify-center items-center space-y-4"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= label(f, :name, class: "title text-lg text-primary-500") %>
        <%= text_input(f, :name,
          class: "input input-primary col-span-2",
          placeholder: "My cool ammo can"
        ) %>
        <span class="col-span-3">
          <%= error_tag(f, :name) %>
        </span>
        <%= label(f, :desc, class: "title text-lg text-primary-500") %>
        <%= textarea(f, :desc,
          class: "input input-primary col-span-2",
          phx_hook: "MaintainAttrs",
          placeholder: "Metal ammo can with the anime girl sticker"
        ) %>
        <span class="col-span-3">
          <%= error_tag(f, :desc) %>
        </span>
        <%= label(f, :type, class: "title text-lg text-primary-500") %>
        <%= text_input(f, :type,
          class: "input input-primary col-span-2",
          placeholder: "Magazine, Clip, Ammo Box, etc"
        ) %>
        <span class="col-span-3">
          <%= error_tag(f, :type) %>
        </span>
        <%= label(f, :location, class: "title text-lg text-primary-500") %>
        <%= textarea(f, :location,
          class: "input input-primary col-span-2",
          phx_hook: "MaintainAttrs",
          placeholder: "On the bookshelf"
        ) %>
        <span class="col-span-3">
          <%= error_tag(f, :location) %>
        </span>
        <%= submit("Save",
          class: "mx-auto btn btn-primary col-span-3",
          phx_disable_with: "Saving..."
        ) %>
      </.form>
    </div>
    """
  end

  defp save_container(socket, :edit, container_params) do
    case Containers.update_container(socket.assigns.container, container_params) do
      {:ok, _container} ->
        {:noreply,
         socket
         |> put_flash(:info, "Container updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_container(socket, :new, container_params) do
    case Containers.create_container(container_params) do
      {:ok, _container} ->
        {:noreply,
         socket
         |> put_flash(:info, "Container created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
