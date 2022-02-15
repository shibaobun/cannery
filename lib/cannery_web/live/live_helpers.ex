defmodule CanneryWeb.LiveHelpers do
  @moduledoc """
  Contains common helper functions for liveviews
  """

  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers
  alias Cannery.Accounts
  alias Phoenix.LiveView.JS

  def assign_defaults(socket, %{"user_token" => user_token} = _session) do
    socket
    |> assign_new(:current_user, fn -> Accounts.get_user_by_session_token(user_token) end)
  end

  def assign_defaults(socket, _session) do
    socket
  end

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.<%= schema.singular %>_index_path(@socket, :index)}>
        <.live_component
          module={<%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.FormComponent}
          id={@<%= schema.singular %>.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.<%= schema.singular %>_index_path(@socket, :index)}
          <%= schema.singular %>: @<%= schema.singular %>
        />
      </.modal>
  """
  def modal(assigns) do
    ~H"""
    <div
      id="modal"
      class="fade-in fixed z-10 left-0 top-0
      w-full h-full overflow-hidden
      p-8 flex flex-col justify-center items-center"
      style="opacity: 1 !important; background-color: rgba(0,0,0,0.4);"
      phx-remove={hide_modal()}
    >
      <div
        id="modal-content"
        class="fade-in-scale w-full max-w-3xl max-h-128 relative overflow-y-auto
        flex flex-col justify-start items-center
        bg-white border-2 rounded-lg"
        phx-click-away={hide_modal()}
        phx-window-keydown={hide_modal()}
        phx-key="escape"
      >
        <%= live_patch to: @return_to,
                   id: "close",
                   class:
                     "absolute top-8 right-10 text-gray-500 hover:text-gray-800 transition-all duration-500 ease-in-out",
                   phx_click: hide_modal() do %>
          <i class="fa-fw fa-lg fas fa-times"></i>
        <% end %>

        <div class="p-8 flex flex-col space-y-4 justify-start items-center">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
