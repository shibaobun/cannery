defmodule CanneryWeb.ViewHelpers do
  @moduledoc """
  Contains common helpers that can be used in liveviews and regular views. These
  are automatically imported into any Phoenix View using `use CanneryWeb,
  :view`
  """

  import Phoenix.Component

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
    <time
      id={@id}
      datetime={@datetime}
      x-data={"{
        date:
          Intl.DateTimeFormat([], {dateStyle: 'short', timeStyle: 'long'})
            .format(new Date(\"#{@datetime}\"))
      }"}
      x-text="date"
    >
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
    <time
      id={@id}
      datetime={@date}
      x-data={"{
        date:
          Intl.DateTimeFormat([], {timeZone: 'Etc/UTC', dateStyle: 'short'}).format(new Date(\"#{@date}\"))
      }"}
      x-text="date"
    >
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
  Get a random color in `#ffffff` hex format

  ## Examples

      iex> random_color()
      "#cc0066"
  """
  @spec random_color() :: <<_::7>>
  def random_color do
    ["#cc0066", "#ff6699", "#6666ff", "#0066cc", "#00cc66", "#669900", "#ff9900", "#996633"]
    |> Enum.random()
  end
end
