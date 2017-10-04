use Mix.Config

config :auth, :env, :prod

config :auth, Moview.Auth.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 15

