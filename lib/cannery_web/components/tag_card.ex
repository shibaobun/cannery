defmodule CanneryWeb.Components.TagCard do
  @moduledoc """
  Display card for a tag
  """

  use CanneryWeb, :component

  def tag_card(assigns) do
    ~H"""
    <div
      id={"tag-#{@tag.id}"}
      class="mx-4 my-2 px-8 py-4 space-x-4 flex justify-center items-center
          border border-gray-400 rounded-lg shadow-lg hover:shadow-md
          transition-all duration-300 ease-in-out"
    >
      <.simple_tag_card tag={@tag} />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def simple_tag_card(assigns) do
    ~H"""
    <h1
      class="inline-block break-all mx-2 my-1 px-4 py-2 rounded-lg title text-xl"
      style={"color: #{@tag.text_color}; background-color: #{@tag.bg_color}"}
    >
      <%= @tag.name %>
    </h1>
    """
  end
end
