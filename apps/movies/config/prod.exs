use Mix.Config

config :movies, :env, :prod

config :logger,
  level: :info

config :logger,
  backends: [{LoggerFileBackend, :info},
               {LoggerFileBackend, :error}]

config :logger, :info,
  path: "../../logs/movies/info.log",
  format: "[$date] [$time] [$level] $metadata $levelpad$message\n",
  metadata: [:date, :application, :module, :function, :line],
  level: :warn

config :logger, :error,
  path: "../../logs/movies/error.log",
  format: "[$date] [$time] [$level] $metadata $levelpad$message\n",
  metadata: [:date, :application, :module, :function, :line],
  level: :error

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 15

