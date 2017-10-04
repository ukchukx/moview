use Mix.Config

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 15

