use Mix.Config

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  timeout: 60_000,
  pool_timeout: 60_000,
  ownership_timeout: 60_000,
  pool: Ecto.Adapters.SQL.Sandbox

