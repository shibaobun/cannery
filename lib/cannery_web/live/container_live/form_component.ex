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
    assigns = assigns |> Map.put(:changeset, container |> Containers.change_container())
    {:ok, socket |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", %{"container" => container_params}, socket) do
    changeset = socket.assigns.container |> Containers.change_container(container_params)
    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"container" => container_params}, socket) do
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
        <%= if @changeset.action do %>
          <div class="invalid-feedback col-span-3 text-center">
            <%= changeset_errors(@changeset) %>
          </div>
        <% end %>

        <%= label(f, :name, gettext("Name"), class: "title text-lg text-primary-500") %>
        <%= text_input(f, :name,
          class: "input input-primary col-span-2",
          placeholder: gettext("My cool ammo can")
        ) %>
        <%= error_tag(f, :name, "col-span-3 text-center") %>

        <%= label(f, :desc, gettext("Description"), class: "title text-lg text-primary-500") %>
        <%= textarea(f, :desc,
          class: "input input-primary col-span-2",
          phx_hook: "MaintainAttrs",
          placeholder: gettext("Metal ammo can with the anime girl sticker")
        ) %>
        <%= error_tag(f, :desc, "col-span-3 text-center") %>

        <%= label(f, :type, gettext("Type"), class: "title text-lg text-primary-500") %>
        <%= text_input(f, :type,
          class: "input input-primary col-span-2",
          placeholder: gettext("Magazine, Clip, Ammo Box, etc")
        ) %>
        <%= error_tag(f, :type, "col-span-3 text-center") %>

        <%= label(f, :location, gettext("Location"), class: "title text-lg text-primary-500") %>
        <%= textarea(f, :location,
          class: "input input-primary col-span-2",
          phx_hook: "MaintainAttrs",
          placeholder: gettext("On the bookshelf")
        ) %>
        <%= error_tag(f, :location, "col-span-3 text-center") %>

        <%= submit(dgettext("actions", "Save"),
          class: "mx-auto btn btn-primary col-span-3",
          phx_disable_with: dgettext("prompts", "Saving...")
        ) %>
      </.form>
    </div>
    """
  end

  defp save_container(socket, :edit, container_params) do
    Containers.update_container(
      socket.assigns.container,
      socket.assigns.current_user,
      container_params
    )
    |> case do
      {:ok, _container} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("prompts", "Container updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_container(socket, :new, container_params) do
    container_params
    |> Containers.create_container(socket.assigns.current_user)
    |> case do
      {:ok, _container} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("prompts", "Container created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
