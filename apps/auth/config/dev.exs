use Mix.Config

config :auth, :env, :dev

config :auth, Moview.Auth.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_dev",
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: "localhost",
  pool_size: 10
