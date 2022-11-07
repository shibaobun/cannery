defmodule CanneryWeb.ViewHelpers do
  @moduledoc """
  Contains common helpers that can be used in liveviews and regular views. These
  are automatically imported into any Phoenix View using `use CanneryWeb,
  :view`
  """

  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  @id_length 16

  @doc """
  Returns a <time> element that renders the naivedatetime in the user's local
  timezone with Alpine.js
  """
  @spec display_datetime(NaiveDateTime.t() | nil) :: Phoenix.LiveView.Rendered.t()
  def display_datetime(nil), do: ""

  def display_datetime(datetime) do
    assigns = %{
      id: :crypto.strong_rand_bytes(@id_length) |> Base.url_encode64(),
      datetime: datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(:extended)
    }

    ~H"""
    <time id={@id} datetime={@datetime} x-data={"{
        date:
          Intl.DateTimeFormat([], {dateStyle: 'short', timeStyle: 'long'})
            .format(new Date(\"#{@datetime}\"))
      }"} x-text="date">
      <%= @datetime %>
    </time>
    """
  end

  @doc """
  Returns a <date> element that renders the Date in the user's local
  timezone with Alpine.js
  """
  @spec display_date(Date.t() | nil) :: Phoenix.LiveView.Rendered.t()
  def display_date(nil), do: ""

  def display_date(date) do
    assigns = %{
      id: :crypto.strong_rand_bytes(@id_length) |> Base.url_encode64(),
      date: date |> Date.to_iso8601(:extended)
    }

    ~H"""
    <time id={@id} datetime={@date} x-data={"{
        date:
          Intl.DateTimeFormat([], {timeZone: 'Etc/UTC', dateStyle: 'short'}).format(new Date(\"#{@date}\"))
      }"} x-text="date">
      <%= @date %>
    </time>
    """
  end

  @doc """
  Displays emoji as text emoji if SHIBAO_MODE is set to true :)
  """
  @spec display_emoji(String.t()) :: String.t()
  def display_emoji("😔"),
    do:
      if(Application.get_env(:cannery, CanneryWeb.ViewHelpers)[:shibao_mode], do: "q_q", else: "😔")

  def display_emoji(other_emoji), do: other_emoji

  @doc """
  A toggle button element that can be directed to a liveview or a
  live_component's `handle_event/3`.

  ## Examples

  <.toggle_button action="my_liveview_action" value={@some_value}>
    <span>Toggle me!</span>
  </.toggle_button>
  <.toggle_button action="my_live_component_action" target={@myself} value={@some_value}>
    <span>Whatever you want</span>
  </.toggle_button>
  """
  def toggle_button(assigns) do
    assigns = assigns |> assign_new(:id, fn -> assigns.action end)

    ~H"""
    <label for={@id} class="inline-flex relative items-center cursor-pointer">
      <input
        type="checkbox"
        value={@value}
        checked={@value}
        id={@id}
        class="sr-only peer"
        {
          if assigns |> Map.has_key?(:target),
            do: %{"phx-click" => @action, "phx-value-value" => @value, "phx-target" => @target},
            else: %{"phx-click" => @action, "phx-value-value" => @value}
        }
      />
      <div class="w-11 h-6 bg-gray-200 rounded-full peer dark:bg-gray-700 peer-focus:ring-4 peer-focus:ring-teal-300 dark:peer-focus:ring-teal-800 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-1 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-teal-600">
      </div>
      <span class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300">
        <%= render_slot(@inner_block) %>
      </span>
    </label>
    """
  end
end
