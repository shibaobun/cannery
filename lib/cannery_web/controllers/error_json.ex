defmodule CanneryWeb.ErrorJSON do
  import CanneryWeb.Gettext

  def render(template, _assigns) do
    error_string =
      case template do
        "404.json" -> dgettext("errors", "Not found")
        "401.json" -> dgettext("errors", "Unauthorized")
        _other_path -> dgettext("errors", "Internal server error")
      end

    %{errors: %{detail: error_string}}
  end
end
