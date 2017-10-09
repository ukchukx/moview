use Mix.Config

config :auth, :env, :test

config :auth, Moview.Auth.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_test",
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: "localhost",
  timeout: 15_000,
  pool_timeout: 15_000,
  ownership_timeout: 15_000,
  pool: Ecto.Adapters.SQL.Sandbox

