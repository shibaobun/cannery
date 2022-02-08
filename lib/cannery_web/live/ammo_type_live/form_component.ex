defmodule CanneryWeb.AmmoTypeLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Cannery.Ammo.AmmoType
  """

  use CanneryWeb, :live_component

  alias Cannery.Ammo
  alias Ecto.Changeset

  @impl true
  def update(%{ammo_type: ammo_type} = assigns, socket) do
    changeset = Ammo.change_ammo_type(ammo_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"ammo_type" => ammo_type_params}, socket) do
    changeset = socket.assigns.ammo_type |> Ammo.change_ammo_type(ammo_type_params)
    {:noreply, socket |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"ammo_type" => ammo_type_params}, socket) do
    save_ammo_type(socket, socket.assigns.action, ammo_type_params)
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

        <%= label(f, :name, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :name, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :name, "col-span-3 text-center") %>

        <%= label(f, :desc, class: "mr-4 title text-lg text-primary-500") %>
        <%= textarea(f, :desc,
          class: "text-center col-span-2 input input-primary",
          phx_hook: "MaintainAttrs"
        ) %>
        <%= error_tag(f, :desc, "col-span-3 text-center") %>

        <a
          href="https://en.wikipedia.org/wiki/Bullet#Abbreviations"
          class="col-span-3 text-center link title text-md text-primary-600"
        >
          Example bullet type abbreviations
        </a>
        <%= label(f, :bullet_type, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :bullet_type,
          class: "text-center col-span-2 input input-primary",
          placeholder: "FMJ"
        ) %>
        <%= error_tag(f, :bullet_type, "col-span-3 text-center") %>

        <%= label(f, :bullet_core, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :bullet_core,
          class: "text-center col-span-2 input input-primary",
          placeholder: "Steel"
        ) %>
        <%= error_tag(f, :bullet_core, "col-span-3 text-center") %>

        <%= label(f, :cartridge, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :cartridge,
          class: "text-center col-span-2 input input-primary",
          placeholder: "5.56x46mm NATO"
        ) %>
        <%= error_tag(f, :cartridge, "col-span-3 text-center") %>

        <%= label(f, :caliber, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :caliber,
          class: "text-center col-span-2 input input-primary",
          placeholder: ".223"
        ) %>
        <%= error_tag(f, :caliber, "col-span-3 text-center") %>

        <%= label(f, :case_material, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :case_material,
          class: "text-center col-span-2 input input-primary",
          placeholder: "Brass"
        ) %>
        <%= error_tag(f, :case_material, "col-span-3 text-center") %>

        <%= label(f, :grains, class: "mr-4 title text-lg text-primary-500") %>
        <%= number_input(f, :grains,
          step: "1",
          class: "text-center col-span-2 input input-primary",
          min: 1
        ) %>
        <%= error_tag(f, :grains, "col-span-3 text-center") %>

        <%= label(f, :pressure, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :pressure,
          class: "text-center col-span-2 input input-primary",
          placeholder: "+P"
        ) %>
        <%= error_tag(f, :pressure, "col-span-3 text-center") %>

        <%= label(f, :primer_type, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :primer_type,
          class: "text-center col-span-2 input input-primary",
          placeholder: "Boxer"
        ) %>
        <%= error_tag(f, :primer_type, "col-span-3 text-center") %>

        <%= label(f, :rimfire, class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :rimfire, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :rimfire, "col-span-3 text-center") %>

        <%= label(f, :tracer, class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :tracer, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :tracer, "col-span-3 text-center") %>

        <%= label(f, :incendiary, class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :incendiary, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :incendiary, "col-span-3 text-center") %>

        <%= label(f, :blank, class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :blank, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :blank, "col-span-3 text-center") %>

        <%= label(f, :corrosive, class: "mr-4 title text-lg text-primary-500") %>
        <%= checkbox(f, :corrosive, class: "text-center col-span-2 checkbox") %>
        <%= error_tag(f, :corrosive, "col-span-3 text-center") %>

        <%= label(f, :manufacturer, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :manufacturer, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :manufacturer, "col-span-3 text-center") %>

        <%= label(f, :sku, class: "mr-4 title text-lg text-primary-500") %>
        <%= text_input(f, :sku, class: "text-center col-span-2 input input-primary") %>
        <%= error_tag(f, :sku, "col-span-3 text-center") %>

        <%= submit("Save",
          phx_disable_with: "Saving...",
          class: "mx-auto col-span-3 btn btn-primary"
        ) %>
      </.form>
    </div>
    """
  end

  defp save_ammo_type(socket, :edit, ammo_type_params) do
    case Ammo.update_ammo_type(socket.assigns.ammo_type, ammo_type_params) do
      {:ok, _ammo_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo type updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  defp save_ammo_type(socket, :new, ammo_type_params) do
    case Ammo.create_ammo_type(ammo_type_params) do
      {:ok, _ammo_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ammo type created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end
end
