defmodule Cannery.Repo.Migrations.AddAmmoTypeTypesAndShotgunFields do
  use Ecto.Migration

  def change do
    alter table(:ammo_types) do
      # rifle/shotgun/pistol
      add :type, :string, default: "rifle"

      add :wadding, :string
      # target/bird/buck/slug/special
      add :shot_type, :string
      add :shot_material, :string
      add :shot_size, :string
      add :unfired_length, :string
      add :brass_height, :string
      add :chamber_size, :string
      add :load_grains, :integer
      add :shot_charge_weight, :string
      add :dram_equivalent, :string
    end

    create index(:ammo_types, [:type])

    execute(&add_fields_to_search/0, &remove_fields_from_search/0)
  end

  defp add_fields_to_search() do
    execute """
    ALTER TABLE ammo_types
      ALTER COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("name", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("desc", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("type", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("manufacturer", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("upc", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("bullet_type", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("bullet_core", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("cartridge", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("caliber", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("case_material", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("jacket_type", '')), 'D') ||
        setweight(to_tsvector('english', immutable_to_string("muzzle_velocity", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("powder_type", '')), 'D') ||
        setweight(to_tsvector('english', immutable_to_string("powder_grains_per_charge", '')), 'D') ||
        setweight(to_tsvector('english', immutable_to_string("grains", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("pressure", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("primer_type", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("firing_type", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("wadding", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_type", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_material", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_size", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("unfired_length", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("brass_height", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("chamber_size", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("load_grains", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_charge_weight,", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("dram_equivalent", '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("tracer", 'tracer', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("incendiary", 'incendiary', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("blank", 'blank', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("corrosive", 'corrosive', '')), 'D')
        setwe
      ) STORED
    """
  end

  defp remove_fields_from_search() do
    execute """
    ALTER TABLE ammo_types
      ALTER COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("name", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("desc", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("bullet_type", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("bullet_core", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("cartridge", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("caliber", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("case_material", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("jacket_type", '')), 'C') ||
        setweight(to_tsvector('english', immutable_to_string("muzzle_velocity", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("powder_type", '')), 'C') ||
        setweight(to_tsvector('english', immutable_to_string("powder_grains_per_charge", '')), 'C') ||
        setweight(to_tsvector('english', immutable_to_string("grains", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("pressure", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("primer_type", '')), 'C') ||
        setweight(to_tsvector('english', coalesce("firing_type", '')), 'C') ||
        setweight(to_tsvector('english', boolean_to_string("tracer", 'tracer', '')), 'C') ||
        setweight(to_tsvector('english', boolean_to_string("incendiary", 'incendiary', '')), 'C') ||
        setweight(to_tsvector('english', boolean_to_string("blank", 'blank', '')), 'C') ||
        setweight(to_tsvector('english', boolean_to_string("corrosive", 'corrosive', '')), 'C') ||
        setweight(to_tsvector('english', coalesce("manufacturer", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("upc", '')), 'D')
      ) STORED
    """
  end
end
