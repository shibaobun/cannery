defmodule CanneryWeb.ContainerLive.FormComponent do
  use CanneryWeb, :live_component

  alias Cannery.Containers

  @impl true
  def update(%{container: container} = assigns, socket) do
    changeset = Containers.change_container(container)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"container" => container_params}, socket) do
    changeset =
      socket.assigns.container
      |> Containers.change_container(container_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"container" => container_params}, socket) do
    save_container(socket, socket.assigns.action, container_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2><%= @title %></h2>

      <.form let={f} for={@changeset}
        id="container-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save">

        <%= label f, :name, class: "title text-lg text-primary-500" %>
        <%= text_input f, :name, class: "input input-primary" %>
        <%= error_tag f, :name %>

        <%= label f, :desc, class: "title text-lg text-primary-500" %>
        <%= text_input f, :desc, class: "input input-primary" %>
        <%= error_tag f, :desc %>

        <%= label f, :type, class: "title text-lg text-primary-500" %>
        <%= text_input f, :type, class: "input input-primary" %>
        <%= error_tag f, :type %>

        <%= label f, :location, class: "title text-lg text-primary-500" %>
        <%= text_input f, :location, class: "input input-primary" %>
        <%= error_tag f, :location %>

        <%= submit "Save", phx_disable_with: "Saving..." %>
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

      {:error, %Ecto.Changeset{} = changeset} ->
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
