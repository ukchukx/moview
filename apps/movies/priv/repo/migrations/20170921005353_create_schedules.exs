defmodule Moview.Movies.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :movie_id, references(:movies, on_delete: :delete_all, type: :bigint)
      add :cinema_id, references(:cinemas, on_delete: :delete_all, type: :bigint)
      add :data, :map

      timestamps()
    end
  end
end
