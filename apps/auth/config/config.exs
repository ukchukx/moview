use Mix.Config

config :auth, ecto_repos: [Moview.Auth.Repo]

config :auth, :services,
  user: :user_service

import_config "#{Mix.env}.exs"
