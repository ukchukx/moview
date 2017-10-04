defmodule Moview.Movies.Repo.Migrations.CreateRatings do
  use Ecto.Migration

  def change do
    create table(:ratings, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :data, :map

      timestamps()
    end

    execute "DROP INDEX IF EXISTS ratings_name_idx"
    execute "CREATE UNIQUE INDEX ratings_name_idx ON ratings((data->>'name'))"

  end
end
