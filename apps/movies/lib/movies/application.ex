defmodule Moview.Movies.Application do
  require Logger

  alias Moview.Movies.{Schedule, Movie, Cinema}

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Moview.Movies.Repo, []),
      worker(Schedule.Impl.Cache, []),
      worker(Movie.Impl.Cache, []),
      worker(Cinema.Impl.Cache, [])
    ]

    case type do
      :normal ->
        Logger.info("Application is started on #{node()}")
      {:takeover, old_node} ->
        Logger.info("#{node()} is taking over #{old_node}")
      {:failover, old_node} ->
        Logger.info("#{old_node} is failing over to #{node()}")
    end

    opts = [strategy: :one_for_one, name: {:global, Moview.Movies.Supervisor}]

    Supervisor.start_link(children, opts)
  end
end
