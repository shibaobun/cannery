defmodule CanneryWeb.AmmoTypeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_component
  alias Cannery.Ammo
  alias Ecto.Changeset

  @impl true
  def update(%{ammo_type: ammo_type} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:changeset, Ammo.change_ammo_type(ammo_type))}
  end

  @impl true
  def handle_event(
        "validate",
        %{"ammo_type" => ammo_type_params},
        %{assigns: %{ammo_type: ammo_type}} = socket
      ) do
    {:noreply, socket |> assign(:changeset, ammo_type |> Ammo.change_ammo_type(ammo_type_params))}
  end

  def handle_event(
        "save",
        %{"ammo_type" => ammo_type_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_ammo_type(socket, action, ammo_type_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-center title text-xl text-primary-500">
        <%= @title %>
      </h2>
      <.form
        let={f}
        for={@changeset}
        id="ammo_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="grid grid-cols-3 justify-center items-center space-y-4"
      >
        <%= if @changeset.action do %>
          <div class="invalid-feedback col-span-3 text-center">
            <%= changeset_errors(@changeset) %>
          </div>
        <% end %>

        <%= label(f, :name, gettext("Name"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :name, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :name, "col-span-3 text-center") %>

        <%= label(f, :desc, gettext("Description"), class: "mr-4 title text-lg text-primary-500") %>
        <%= textarea(f, :desc,
          class: "text-center col-span-2 input input-primary",
          phx_hook: "MaintainAttrs"
        ) %>
        <%= error_tag(f, :desc, "col-span-3 text-center") %>

        <a
          href="https://en.wikipedia.org/wiki/Bullet#Abbreviations"
          class="col-span-3 text-center link title text-md text-primary-600"
        >
          <%= gettext("Example bullet type abbreviations") %>
        </a>
        <%= label(f, :bullet_type, gettext("Bullet type"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :bullet_type,
          class: "text-center col-span-2 input input-primary",
          placeholder: gettext("FMJ")
        ) %>
        <%= error_tag(f, :bullet_type, "col-span-3 text-center") %>

        <%= label(f, :bullet_core, gettext("Bullet core"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :bullet_core,
          class: "text-center col-span-2 input input-primary",
          placeholder: gettext("Steel")
        ) %>
        <%= error_tag(f, :bullet_core, "col-span-3 text-center") %>

        <%= label(f, :cartridge, gettext("Cartridge"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :cartridge,
          class: "text-center col-span-2 input input-primary",
          placeholder: "5.56x46mm NATO"
        ) %>
        <%= error_tag(f, :cartridge, "col-span-3 text-center") %>

        <%= label(f, :caliber, gettext("Caliber"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :caliber,
          class: "text-center col-span-2 input input-primary",
          placeholder: ".223"
        ) %>
        <%= error_tag(f, :caliber, "col-span-3 text-center") %>

        <%= label(f, :case_material, gettext("Case material"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :case_material,
          class: "text-center col-span-2 input input-primary",
          placeholder: gettext("Brass")
        ) %>
        <%= error_tag(f, :case_material, "col-span-3 text-center") %>

        <%= label(f, :grains, gettext("Grains"), class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :grains,
          step: "1",
          class: "text-center col-span-2 input input-primary",
          min: 1
        ) %>
        <%= error_tag(f, :grains, "col-span-3 text-center") %>

        <%= label(f, :pressure, gettext("Pressure"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :pressure,
          class: "text-center col-span-2 input input-primary",
          placeholder: "+P"
        ) %>
        <%= error_tag(f, :pressure, "col-span-3 text-center") %>

        <%= label(f, :primer_type, gettext("Primer type"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :primer_type,
          class: "text-center col-span-2 input input-primary",
          placeholder: "Boxer"
        ) %>
        <%= error_tag(f, :primer_type, "col-span-3 text-center") %>

        <%= label(f, :rimfire, gettext("Rimfire"), class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :rimfire, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :rimfire, "col-span-3 text-center") %>

        <%= label(f, :tracer, gettext("Tracer"), class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :tracer, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :tracer, "col-span-3 text-center") %>

        <%= label(f, :incendiary, gettext("Incendiary"), class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :incendiary, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :incendiary, "col-span-3 text-center") %>

        <%= label(f, :blank, gettext("Blank"), class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :blank, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :blank, "col-span-3 text-center") %>

        <%= label(f, :corrosive, gettext("Corrosive"), class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :corrosive, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :corrosive, "col-span-3 text-center") %>

        <%= label(f, :manufacturer, gettext("Manufacturer"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :manufacturer, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :manufacturer, "col-span-3 text-center") %>

        <%= label(f, :sku, gettext("SKU"), class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :sku, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :sku, "col-span-3 text-center") %>

        <%= submit(dgettext("actions", "Save"),
          phx_disable_with: dgettext("prompts", "Saving..."),
          class: "mx-auto col-span-3 btn btn-primary"
        ) %>
      </.form>
    </div>
    """
  end

  defp save_ammo_type(
         %{assigns: %{ammo_type: ammo_type, current_user: current_user, return_to: return_to}} =
           socket,
         :edit,
         ammo_type_params
       ) do
    socket =
      case Ammo.update_ammo_type(ammo_type, ammo_type_params, current_user) do
        {:ok, %{name: ammo_type_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: ammo_type_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_ammo_type(%{assigns: %{return_to: return_to}} = socket, :new, ammo_type_params) do
    socket =
      case Ammo.create_ammo_type(ammo_type_params) do
        {:ok, %{name: ammo_type_name}} ->
          prompt = dgettext("prompts", "%{name} created successfully", name: ammo_type_name)
          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
