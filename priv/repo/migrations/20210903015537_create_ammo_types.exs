defmodule Cannery.Repo.Migrations.CreateAmmoTypes do
  use Ecto.Migration

  def change do
    create table(:ammo_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :desc, :text
      add :case_material, :string
      add :bullet_type, :string
      add :grain, :integer
      add :manufacturer, :string

      timestamps()
    end
  end
end
