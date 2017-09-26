defmodule Moview.Auth.Application do
  require Logger

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Moview.Auth.Repo, []),
      worker(Moview.Auth.User.Impl.Cache, [])
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

    Supervisor.start_link(children, opts)
  end
end
