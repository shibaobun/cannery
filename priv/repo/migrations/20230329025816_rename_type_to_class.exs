defmodule Cannery.Repo.Migrations.RenameTypeToClass do
  use Ecto.Migration

  def change do
    rename table(:ammo_types), :type, to: :class
  end
end
