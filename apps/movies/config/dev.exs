use Mix.Config

config :movies, :env, :dev

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_dev",
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: "localhost",
  pool_size: 10

