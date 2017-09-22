defmodule Moview.Movies.Application do
  require Logger

  alias Moview.Movies.Movie.Server, as: MovieServer
  alias Moview.Movies.Cinema.Server, as: CinemaServer
  alias Moview.Movies.Schedule.Server, as: ScheduleServer

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Moview.Movies.Repo, []),
      worker(MovieServer, []),
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
