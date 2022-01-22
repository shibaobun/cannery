defmodule CanneryWeb.TagLive.FormComponent do
  use CanneryWeb, :live_component

  alias Cannery.Tags

  @impl true
  def update(%{tag: tag} = assigns, socket) do
    changeset = Tags.change_tag(tag)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    tag_params = tag_params |> Map.put("user_id", socket.assigns.current_user.id)

    changeset =
      socket.assigns.tag
      |> Tags.change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"tag" => tag_params}, socket) do
    tag_params = tag_params |> Map.put("user_id", socket.assigns.current_user.id)
    save_tag(socket, socket.assigns.action, tag_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="title text-xl text-primary-500">
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="tag-form"
        class="grid grid-cols-3 justify-center items-center space-y-4"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save">

        <%= label f, :name, class: "title text-lg text-primary-500" %>
        <%= text_input f, :name, class: "input input-primary col-span-2" %>
        <span class="col-span-3">
          <%= error_tag(f, :name) %>
        </span>
        <%= label(f, :bg_color, class: "title text-lg text-primary-500") %>
        <span class="mx-auto col-span-2" phx-update="ignore">
          <%= color_input(f, :bg_color, value: random_color()) %>
        </span>
        <span class="col-span-3">
          <%= error_tag(f, :bg_color) %>
        </span>
        <%= label(f, :text_color, class: "title text-lg text-primary-500") %>
        <span class="mx-auto col-span-2" phx-update="ignore">
          <%= color_input(f, :text_color, value: "#ffffff") %>
        </span>
        <span class="col-span-3">
          <%= error_tag(f, :text_color) %>
        </span>
        <%= submit("Save",
          class: "mx-auto btn btn-primary col-span-3",
          phx_disable_with: "Saving..."
        ) %>
      </.form>
    </div>
    """
  end

  defp save_tag(socket, :edit, tag_params) do
    case Tags.update_tag(socket.assigns.tag, tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_tag(socket, :new, tag_params) do
    case Tags.create_tag(tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end-
  @doc """
  Returns a random tag color in `#ffffff` hex format
  """
  @spec random_color() :: String.t()
  def random_color() do
    ["#cc0066", "#ff6699", "#6666ff", "#0066cc", "#00cc66", "#669900", "#ff9900", "#996633"]
    |> Enum.random()
  end
end
