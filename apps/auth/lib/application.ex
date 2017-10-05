defmodule Moview.Auth.Application do
  require Logger

  alias Moview.Auth.{Repo, User}

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Repo, []),
      worker(User.Impl.Cache, [])
    ]

    Logger.info("Auth app started.")

    case type do
      :normal ->
        Logger.info("Application is started on #{node()}")
      {:takeover, old_node} ->
        Logger.info("#{node()} is taking over #{old_node}")
      {:failover, old_node} ->
        Logger.info("#{old_node} is failing over to #{node()}")
    end

    opts = [strategy: :one_for_one, name: {:global, Moview.Auth.Supervisor}]

    case Supervisor.start_link(children, opts) do
      {:ok, _} = res ->
        if Application.get_env(:auth, :env) != :test do
          # Run migrations
          Logger.info "Running migrations"
          path = Application.app_dir(:auth, "priv/repo/migrations")
          Ecto.Migrator.run(Repo, path, :up, all: true)
          # Seed cache
          User.seed_from_db()
        end
        res
      {:error, _} = res ->
        res
    end
  end
end
