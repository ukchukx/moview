defmodule Moview.Scraper.Application do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Moview.Scraper.Scheduler, [])
    ]

    Logger.info "Scraper app started."

    opts = [strategy: :one_for_one, name: Moview.Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
