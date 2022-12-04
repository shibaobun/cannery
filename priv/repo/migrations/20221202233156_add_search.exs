defmodule Cannery.Repo.Migrations.AddSearch do
  use Ecto.Migration

  def up do
    execute """
    CREATE FUNCTION immutable_to_string(integer, text)
      RETURNS text LANGUAGE sql IMMUTABLE as
        $$SELECT coalesce(($1)::TEXT, $2)::TEXT$$
    """

    execute """
    CREATE FUNCTION immutable_to_string(double precision, text)
      RETURNS text LANGUAGE sql IMMUTABLE as
        $$SELECT coalesce(($1)::TEXT, $2)::TEXT$$
    """

    execute """
    CREATE FUNCTION immutable_to_string(date, text)
      RETURNS text LANGUAGE sql IMMUTABLE as
        $$SELECT coalesce(($1)::TEXT, $2)::TEXT$$
    """

    execute """
    CREATE FUNCTION boolean_to_string(boolean, text, text)
      RETURNS text LANGUAGE sql IMMUTABLE as
        $$SELECT (CASE $1 WHEN true THEN $2 ELSE $3 END)::TEXT$$
    """

    execute """
    ALTER TABLE ammo_groups
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("notes", '')), 'A') ||
        setweight(to_tsvector('english', immutable_to_string("price_paid", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("purchased_on", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("count", '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX ammo_groups_trgm_idx ON ammo_groups USING GIN (search)")

    execute """
    ALTER TABLE containers
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("name", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("desc", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("location", '')), 'B') ||
        setweight(to_tsvector('english', coalesce("type", '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX containers_trgm_idx ON containers USING GIN (search)")

    execute """
    ALTER TABLE tags
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("name", '')), 'A')
      ) STORED
    """

    execute("CREATE INDEX tags_trgm_idx ON tags USING GIN (search)")

    execute """
    ALTER TABLE ammo_types
      ADD COLUMN search tsvector
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

    execute("CREATE INDEX ammo_types_trgm_idx ON ammo_types USING GIN (search)")

    execute """
    ALTER TABLE shot_groups
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(notes, '')), 'A') ||
        setweight(to_tsvector('english', immutable_to_string(count, '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string(date, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX shot_groups_trgm_idx ON shot_groups USING GIN (search)")
  end

  def down do
    alter table(:ammo_groups), do: remove(:search)
    alter table(:containers), do: remove(:search)
    alter table(:tags), do: remove(:search)
    alter table(:ammo_types), do: remove(:search)
    alter table(:shot_groups), do: remove(:search)
    execute("DROP FUNCTION immutable_to_string(double precision, text)")
    execute("DROP FUNCTION immutable_to_string(integer, text)")
    execute("DROP FUNCTION immutable_to_string(date, text)")
    execute("DROP FUNCTION boolean_to_string(boolean, text, text)")
  end
end
