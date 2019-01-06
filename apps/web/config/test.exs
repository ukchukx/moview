use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.

# 10 minute
config :web, schedule_interval: 600

config :web, Moview.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
