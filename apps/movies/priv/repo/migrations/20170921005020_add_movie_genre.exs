defmodule Moview.Movies.Repo.Migrations.AddMovieGenre do
  use Ecto.Migration

  def change do
    create table(:movies_genres, primary_key: false) do
      add :movie_id, references(:movies, type: :bigint, on_delete: :delete_all)
      add :genre_id, references(:genres, type: :bigint, on_delete: :delete_all)
    end
  end
end
