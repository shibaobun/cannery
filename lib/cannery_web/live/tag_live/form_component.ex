defmodule CanneryWeb.TagLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Tags.Tag
  """

  use CanneryWeb, :live_component
  alias Cannery.Tags
  alias Cannery.{Accounts.User, Tags.Tag}
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(%{:tag => Tag.t(), :current_user => User.t(), optional(any) => any}, Socket.t()) ::
          {:ok, Socket.t()}
  def update(%{tag: _tag} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    {:noreply, socket |> assign_changeset(tag_params)}
  end

  def handle_event("save", %{"tag" => tag_params}, %{assigns: %{action: action}} = socket) do
    save_tag(socket, action, tag_params)
  end

  defp assign_changeset(
         %{assigns: %{action: action, current_user: user, tag: tag}} = socket,
         tag_params
       ) do
    changeset_action =
      case action do
        :new -> :insert
        :edit -> :update
      end

    changeset =
      case action do
        :new -> tag |> Tag.create_changeset(user, tag_params)
        :edit -> tag |> Tag.update_changeset(tag_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(changeset_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(:changeset, changeset)
  end

  defp save_tag(
         %{assigns: %{tag: tag, current_user: current_user, return_to: return_to}} = socket,
         :edit,
         tag_params
       ) do
    socket =
      case Tags.update_tag(tag, tag_params, current_user) do
        {:ok, %{name: tag_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: tag_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_tag(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         tag_params
       ) do
    socket =
      case Tags.create_tag(tag_params, current_user) do
        {:ok, %{name: tag_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: tag_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
