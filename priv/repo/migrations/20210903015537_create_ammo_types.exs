defmodule Cannery.Repo.Migrations.CreateAmmoTypes do
  use Ecto.Migration

  def change do
    create table(:ammo_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :desc, :string
      add :case_material, :string
      add :bullet_type, :string
      add :weight, :float
      add :manufacturer, :string

      timestamps()
    end
  end
end
