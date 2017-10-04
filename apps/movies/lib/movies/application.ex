defmodule Moview.Movies.Application do
  require Logger

  alias Moview.Movies.{Repo, Schedule, Movie, Cinema}

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Repo, []),
      worker(Movie.Impl.Cache, []),
      worker(Cinema.Impl.Cache, []),
      worker(Schedule.Impl.Cache, [])
    ]

    Logger.info("Movie app started.")

    case type do
      :normal ->
        Logger.info("Application is started on #{node()}")
      {:takeover, old_node} ->
        Logger.info("#{node()} is taking over #{old_node}")
      {:failover, old_node} ->
        Logger.info("#{old_node} is failing over to #{node()}")
    end

    opts = [strategy: :one_for_one, name: {:global, Moview.Movies.Supervisor}]

    case Supervisor.start_link(children, opts) do
      {:ok, _} = res ->
        if Application.get_env(:movies, :env) != :test do
          # Run migrations
          Logger.info "Running migrations"
          path = Application.app_dir(:movies, "priv/repo/migrations")
          Ecto.Migrator.run(Repo, path, :up, all: true)

          Cinema.seed()
          # Seed caches
          Movie.seed_from_db()
          Cinema.seed_from_db()
          Schedule.seed_from_db()
        end
        res
      {:error, _} = res ->
        res
    end
  end
end
