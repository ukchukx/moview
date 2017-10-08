use Mix.Config

config :logger,
  level: :info

config :logger,
  backends: [{LoggerFileBackend, :info},
               {LoggerFileBackend, :error}]

config :logger, :info,
  path: "../../logs/scraper/info.log",
  format: "[$date] [$time] [$level] $metadata $levelpad$message\n",
  metadata: [:date, :application, :module, :function, :line],
  level: :warn

config :logger, :error,
  path: "../../logs/scraper/error.log",
  format: "[$date] [$time] [$level] $metadata $levelpad$message\n",
  metadata: [:date, :application, :module, :function, :line],
  level: :error

