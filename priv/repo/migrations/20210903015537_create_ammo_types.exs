defmodule Cannery.Repo.Migrations.CreateAmmoTypes do
  use Ecto.Migration

  def change do
    create table(:ammo_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :desc, :text

      # https://en.wikipedia.org/wiki/Bullet#Abbreviations
      add :bullet_type, :string
      add :bullet_core, :string
      add :cartridge, :string
      add :caliber, :string
      add :case_material, :string
      add :grains, :integer
      add :pressure, :string
      add :rimfire, :boolean, null: false, default: false
      add :tracer, :boolean, null: false, default: false
      add :incendiary, :boolean, null: false, default: false
      add :blank, :boolean, null: false, default: false
      add :corrosive, :boolean, null: false, default: false

      add :manufacturer, :string
      add :sku, :string

      timestamps()
    end
  end
end
