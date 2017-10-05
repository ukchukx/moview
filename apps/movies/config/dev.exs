use Mix.Config

config :movies, :env, :dev

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

