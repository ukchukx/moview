defmodule Moview.Movies.Repo.Migrations.CreateGenres do
  use Ecto.Migration

  def change do
    create table(:genres, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :data, :map

      timestamps()
    end

    execute "DROP INDEX IF EXISTS genres_name_idx"
    execute "CREATE UNIQUE INDEX genres_name_idx ON genres((data->>'name'))"

  end
end
