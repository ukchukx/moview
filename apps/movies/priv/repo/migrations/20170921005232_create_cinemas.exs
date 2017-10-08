defmodule Moview.Movies.Repo.Migrations.CreateCinemas do
  use Ecto.Migration

  def change do
    create table(:cinemas, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :data, :map

      timestamps()
    end
  end
end
