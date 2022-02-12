defmodule CanneryWeb.LiveHelpers do
  @moduledoc """
  Contains common helper functions for liveviews
  """

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView, only: [assign_new: 3]
  alias Cannery.Accounts
  alias CanneryWeb.Components.Modal

  @doc """
  Renders a component inside the `Modal` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal CanneryWeb.TagLive.FormComponent,
        id: @tag.id || :new,
        action: @live_action,
        tag: @tag,
        return_to: Routes.tag_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    live_component(Modal, id: :modal, return_to: path, component: component, opts: opts)
  end

  def assign_defaults(socket, %{"user_token" => user_token} = _session) do
    socket
    |> assign_new(:current_user, fn -> Accounts.get_user_by_session_token(user_token) end)
  end

  def assign_defaults(socket, _session) do
    socket
  end
end
