# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :web,
  namespace: Moview.Web

config :web, port: System.get_env("MOVIEW_PORT")

# Configures the endpoint
config :web, Moview.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "5sGUx8LMnJyCv6ntcT9B0Cp5Kol0mmdiGaQVw3wjYaSsRa1oVinmWmS47kT69KWJ",
  render_errors: [view: Moview.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Moview.Web.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
