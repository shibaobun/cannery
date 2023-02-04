defmodule CanneryWeb.ViewHelpers do
  @moduledoc """
  Contains common helpers that can be used in liveviews and regular views. These
  are automatically imported into any Phoenix View using `use CanneryWeb,
  :view`
  """

  use Phoenix.Component

  @doc """
  Phoenix.Component for a <time> element that renders the naivedatetime in the
  user's local timezone with Alpine.js
  """

  attr :datetime, :any, required: true, doc: "A `DateTime` struct or nil"

  def datetime(assigns) do
    ~H"""
    <time
      :if={@datetime}
      datetime={cast_datetime(@datetime)}
      x-data={"{
        datetime:
          Intl.DateTimeFormat([], {dateStyle: 'short', timeStyle: 'long'})
            .format(new Date(\"#{cast_datetime(@datetime)}\"))
      }"}
      x-text="datetime"
    >
      <%= cast_datetime(@datetime) %>
    </time>
    """
  end

  @spec cast_datetime(NaiveDateTime.t() | nil) :: String.t()
  defp cast_datetime(%NaiveDateTime{} = datetime) do
    datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(:extended)
  end

  defp cast_datetime(_datetime), do: ""

  @doc """
  Phoenix.Component for a <date> element that renders the Date in the user's
  local timezone with Alpine.js
  """

  attr :date, :any, required: true, doc: "A `Date` struct or nil"

  def date(assigns) do
    ~H"""
    <time
      :if={@date}
      datetime={@date |> Date.to_iso8601(:extended)}
      x-data={"{
        date:
          Intl.DateTimeFormat([], {timeZone: 'Etc/UTC', dateStyle: 'short'})
            .format(new Date(\"#{@date |> Date.to_iso8601(:extended)}\"))
      }"}
      x-text="date"
    >
      <%= @date |> Date.to_iso8601(:extended) %>
    </time>
    """
  end

  @doc """
  Displays emoji as text emoji if SHIBAO_MODE is set to true :)
  """
  @spec display_emoji(String.t()) :: String.t()
  def display_emoji("😔") do
    if Application.get_env(:cannery, CanneryWeb.ViewHelpers)[:shibao_mode], do: "q_q", else: "😔"
  end

  def display_emoji(other_emoji), do: other_emoji

  @doc """
  Displays content in a QR code as a base64 encoded PNG
  """
  @spec qr_code_image(String.t()) :: String.t()
  @spec qr_code_image(String.t(), width :: non_neg_integer()) :: String.t()
  def qr_code_image(content, width \\ 384) do
    img_data =
      content
      |> EQRCode.encode()
      |> EQRCode.png(width: width)
      |> Base.encode64()

    "data:image/png;base64," <> img_data
  end

  @doc """
  Creates a downloadable QR Code element
  """

  attr :content, :string, required: true
  attr :filename, :string, default: "qrcode", doc: "filename without .png extension"
  attr :image_class, :string, default: "w-64 h-max"
  attr :width, :integer, default: 384, doc: "width of png to generate"

  def qr_code(assigns) do
    ~H"""
    <a href={qr_code_image(@content)} download={@filename <> ".png"}>
      <img class={@image_class} alt={@filename} src={qr_code_image(@content)} />
    </a>
    """
  end

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
