use Mix.Config

config :auth, :env, :test

config :auth, Moview.Auth.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  timeout: 15_000,
  pool_timeout: 15_000,
  ownership_timeout: 15_000,
  pool: Ecto.Adapters.SQL.Sandbox

