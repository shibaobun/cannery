defmodule CanneryWeb.ModalComponent do
  use CanneryWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="fixed z-10 left-0 top-0
      w-full h-full overflow-hidden
      p-8 flex flex-col justify-center items-center"
      style="opacity: 1 !important; background-color: rgba(0,0,0,0.4);"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target="#<%= @id %>"
      phx-page-loading>

      <div class="w-full max-w-4xl relative
        p-8 flex flex-col justify-start items-center
        bg-white border-2 rounded-lg">
        <%# close button %>
        <%= live_patch to: @return_to,
          class: "absolute top-8 right-10 text-gray-500 hover:text-gray-800
            transition-all duration-500 ease-in-out" do %>
          <i class="fa-fw fa-lg fas fa-times"></i>
        <% end %>

        <%# modal content %>
        <div class="w-full flex flex-col space-y-4 justify-center items-center">
          <%= live_component @component, @opts %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
