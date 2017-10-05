use Mix.Config

config :auth, :env, :dev

config :auth, Moview.Auth.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "moview_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
