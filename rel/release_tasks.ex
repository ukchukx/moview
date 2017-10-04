defmodule Moview.Release.Tasks do
  @doc """
  This is a migration hook to work around Mix not being available in production.
  """

  def migrate do
    {:ok, _} = Application.ensure_all_started(:movies)
    {:ok, _} = Application.ensure_all_started(:auth)

    movies_path = Application.app_dir(:movies, "priv/repo/migrations")
    auth_path = Application.app_dir(:auth, "priv/repo/migrations")

    Ecto.Migrator.run(Moview.Movies.Repo, movies_path, :up, all: true)
    Ecto.Migrator.run(Moview.Auth.Repo, auth_path, :up, all: true)
  end
end
