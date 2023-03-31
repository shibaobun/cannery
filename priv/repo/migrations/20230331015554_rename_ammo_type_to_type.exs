defmodule Cannery.Repo.Migrations.RenameAmmoTypeToType do
  use Ecto.Migration

  def change do
    rename table(:ammo_types), to: table(:types)
    rename table(:packs), :ammo_type_id, to: :type_id
  end
end
