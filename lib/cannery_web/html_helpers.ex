defmodule CanneryWeb.HTMLHelpers do
  @moduledoc """
  Contains common helpers that are used for rendering
  """

  use Phoenix.Component

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
