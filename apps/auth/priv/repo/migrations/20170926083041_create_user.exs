defmodule Moview.Auth.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :data, :map

      timestamps()
    end

    execute "DROP INDEX IF EXISTS users_email_idx"
    execute "CREATE UNIQUE INDEX users_email_idx ON users((data->>'email'))"
  end
end
