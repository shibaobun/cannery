defmodule CanneryWeb.TagLive.TagCard do
  @moduledoc """
  Display card for a tag
  """

  use CanneryWeb, :component
  alias CanneryWeb.Endpoint

  def tag_card(assigns) do
    ~H"""
    <div
      id={"tag-#{@tag.id}"}
      class="mx-4 my-2 px-8 py-4 space-x-4 flex justify-center items-center
          border border-gray-400 rounded-lg shadow-lg hover:shadow-md"
    >
      <h1
        class="px-4 py-2 rounded-lg title text-xl"
        style={"color: #{@tag.text_color}; background-color: #{@tag.bg_color}"}
      >
        <%= @tag.name %>
      </h1>

      <%= live_patch to: Routes.tag_index_path(Endpoint, :edit, @tag),
                 class: "text-primary-500 link" do %>
        <i class="fa-fw fa-lg fas fa-edit"></i>
      <% end %>

      <%= link to: "#",
           class: "text-primary-500 link",
           phx_click: "delete",
           phx_value_id: @tag.id,
           data: [
             confirm: dgettext("prompts", "Are you sure you want to delete %{name}?", name: @tag.name)
           ] do %>
        <i class="fa-fw fa-lg fas fa-trash"></i>
      <% end %>
    </div>
    """
  end
end
