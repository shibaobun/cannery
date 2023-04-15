defmodule Cannery.Repo.Migrations.AddPackLotNumberToSearch do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE packs DROP COLUMN search"

    execute """
    ALTER TABLE packs
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("notes", '')), 'A') ||
        setweight(to_tsvector('english', coalesce("lot_number", '')), 'A') ||
        setweight(to_tsvector('english', immutable_to_string("price_paid", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("purchased_on", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("count", '')), 'C')
      ) STORED
    """
  end

  def down do
    execute "ALTER TABLE packs DROP COLUMN search"

    execute """
    ALTER TABLE packs
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce("notes", '')), 'A') ||
        setweight(to_tsvector('english', immutable_to_string("price_paid", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("purchased_on", '')), 'B') ||
        setweight(to_tsvector('english', immutable_to_string("count", '')), 'C')
      ) STORED
    """
  end
end
