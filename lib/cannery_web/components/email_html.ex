defmodule CanneryWeb.EmailHTML do
  @moduledoc """
  Renders email templates
  """

  use CanneryWeb, :html

  embed_templates "email_html/*.html", suffix: "_html"
  embed_templates "email_html/*.txt", suffix: "_text"
end
