defmodule Cannery.Repo.Migrations.RenameTypeToClass do
  use Ecto.Migration

  def up do
    rename table(:ammo_types), :type, to: :class

    alter table(:ammo_types) do
      remove_if_exists :search, :tsvector
    end

    flush()

    execute """
    ALTER TABLE ammo_types
      ADD COLUMN search tsvector
        GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("name", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("desc", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("class", '')), 'B') ||
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
        setweight(to_tsvector('english', immutable_to_string("load_grains", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_charge_weight", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("dram_equivalent", '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("tracer", 'tracer', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("incendiary", 'incendiary', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("blank", 'blank', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("corrosive", 'corrosive', '')), 'D') ||
        setweight(to_tsvector('english', coalesce("manufacturer", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("upc", '')), 'D')
      ) STORED
    """
  end

  def down do
    rename table(:ammo_types), :class, to: :type

    alter table(:ammo_types) do
      remove_if_exists :search, :tsvector
    end

    flush()

    execute """
    ALTER TABLE ammo_types
      ADD COLUMN search TSVECTOR
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
        setweight(to_tsvector('english', immutable_to_string("load_grains", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("shot_charge_weight", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("dram_equivalent", '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("tracer", 'tracer', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("incendiary", 'incendiary', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("blank", 'blank', '')), 'D') ||
        setweight(to_tsvector('english', boolean_to_string("corrosive", 'corrosive', '')), 'D') ||
        setweight(to_tsvector('english', coalesce("manufacturer", '')), 'D') ||
        setweight(to_tsvector('english', coalesce("upc", '')), 'D')
      ) STORED
    """
  end
end
