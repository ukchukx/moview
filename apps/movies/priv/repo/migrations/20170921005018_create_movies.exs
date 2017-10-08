defmodule Moview.Movies.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :rating_id, references(:ratings, on_delete: :nothing, type: :bigint)
      add :data, :map

      timestamps()
    end

    execute "DROP INDEX IF EXISTS movies_slug_idx"
    execute "CREATE UNIQUE INDEX movies_slug_idx ON movies((data->>'slug'))"
  end
end
