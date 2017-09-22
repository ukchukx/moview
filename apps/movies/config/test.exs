use Mix.Config

config :movies, Moview.Movies.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

