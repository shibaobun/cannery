defmodule CanneryWeb.AmmoTypeLive.Index do
  @moduledoc """
  Liveview for showing a Cannery.Ammo.AmmoType index
  """

  use CanneryWeb, :live_view

  alias Cannery.{Ammo, Ammo.AmmoType}
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> list_ammo_types()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Ammo type"))
    |> assign(:ammo_type, Ammo.get_ammo_type!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Ammo type"))
    |> assign(:ammo_type, %AmmoType{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, gettext("Ammo types")) |> assign(:ammo_type, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{name: name} = Ammo.get_ammo_type!(id, current_user) |> Ammo.delete_ammo_type!(current_user)

    prompt = dgettext("prompts", "%{name} deleted succesfully", name: name)

    {:noreply, socket |> put_flash(:info, prompt) |> list_ammo_types()}
  end

  defp list_ammo_types(%{assigns: %{current_user: current_user}} = socket) do
    ammo_types = Ammo.list_ammo_types(current_user)

    columns =
      [
        %{label: gettext("Name"), key: "name", type: :string},
        %{label: gettext("Bullet type"), key: "bullet_type", type: :string},
        %{label: gettext("Bullet core"), key: "bullet_core", type: :string},
        %{label: gettext("Cartridge"), key: "cartridge", type: :string},
        %{label: gettext("Caliber"), key: "caliber", type: :string},
        %{label: gettext("Case material"), key: "case_material", type: :string},
        %{label: gettext("Jacket type"), key: "jacket_type", type: :string},
        %{label: gettext("Muzzle velocity"), key: "muzzle_velocity", type: :string},
        %{label: gettext("Powder type"), key: "powder_type", type: :string},
        %{
          label: gettext("Powder grains per charge"),
          key: "powder_grains_per_charge",
          type: :string
        },
        %{label: gettext("Grains"), key: "grains", type: :string},
        %{label: gettext("Pressure"), key: "pressure", type: :string},
        %{label: gettext("Primer type"), key: "primer_type", type: :string},
        %{label: gettext("Firing type"), key: "firing_type", type: :string},
        %{label: gettext("Tracer"), key: "tracer", type: :boolean},
        %{label: gettext("Incendiary"), key: "incendiary", type: :boolean},
        %{label: gettext("Blank"), key: "blank", type: :boolean},
        %{label: gettext("Corrosive"), key: "corrosive", type: :boolean},
        %{label: gettext("Manufacturer"), key: "manufacturer", type: :string},
        %{label: gettext("UPC"), key: "upc", type: :string}
      ]
      |> Enum.filter(fn %{key: key, type: type} ->
        # remove columns if all values match defaults
        default_value = if type == :boolean, do: false, else: nil

        ammo_types
        |> Enum.any?(fn ammo_type ->
          not (ammo_type |> Map.get(key |> String.to_existing_atom()) == default_value)
        end)
      end)
      |> Kernel.++([
        %{label: gettext("Total # of rounds"), key: "round_count", type: :round_count},
        %{label: gettext("Average Price paid"), key: "avg_price_paid", type: :avg_price_paid},
        %{label: nil, key: "actions", type: :actions, sortable: false}
      ])

    rows =
      ammo_types
      |> Enum.map(fn ammo_type -> ammo_type |> get_ammo_type_values(columns, current_user) end)

    socket |> assign(columns: columns, rows: rows)
  end

  defp get_ammo_type_values(ammo_type, columns, current_user) do
    columns
    |> Enum.into(%{}, fn %{key: key, type: type} ->
      {key, get_ammo_type_value(type, key, ammo_type, current_user)}
    end)
  end

  defp get_ammo_type_value(:boolean, key, ammo_type, _current_user),
    do: ammo_type |> Map.get(key |> String.to_existing_atom()) |> humanize()

  defp get_ammo_type_value(:round_count, _key, ammo_type, current_user),
    do: ammo_type |> Ammo.get_round_count_for_ammo_type(current_user)

  defp get_ammo_type_value(:avg_price_paid, _key, ammo_type, current_user) do
    case ammo_type |> Ammo.get_average_cost_for_ammo_type!(current_user) do
      nil -> gettext("No cost information")
      count -> gettext("$%{amount}", amount: count |> :erlang.float_to_binary(decimals: 2))
    end
  end

  defp get_ammo_type_value(:actions, _key, ammo_type, _current_user) do
    assigns = %{ammo_type: ammo_type}

    ~H"""
    <div class="px-4 py-2 space-x-4 flex justify-center items-center">
      <%= live_redirect to: Routes.ammo_type_show_path(Endpoint, :show, ammo_type),
                    class: "text-primary-600 link",
                    data: [qa: "view-#{ammo_type.id}"] do %>
        <i class="fa-fw fa-lg fas fa-eye"></i>
      <% end %>

      <%= live_patch to: Routes.ammo_type_index_path(Endpoint, :edit, ammo_type),
                  class: "text-primary-600 link",
                  data: [qa: "edit-#{ammo_type.id}"] do %>
        <i class="fa-fw fa-lg fas fa-edit"></i>
      <% end %>

      <%= link to: "#",
            class: "text-primary-600 link",
            phx_click: "delete",
            phx_value_id: ammo_type.id,
            data: [
              confirm: dgettext("prompts", "Are you sure you want to delete %{name}? This will delete all %{name} type ammo as well!", name: ammo_type.name),
              qa: "delete-#{ammo_type.id}"
            ] do %>
        <i class="fa-lg fas fa-trash"></i>
      <% end %>
    </div>
    """
  end

  defp get_ammo_type_value(nil, _key, _ammo_type, _current_user), do: nil

  defp get_ammo_type_value(_other, key, ammo_type, _current_user),
    do: ammo_type |> Map.get(key |> String.to_existing_atom())
end
