# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :scraper, :tmdb,
  key: System.get_env("TMDB_KEY"),
  base_url: "https://api.themoviedb.org/3"

config :scraper, :omdb,
  key: System.get_env("OMDB_KEY"),
  base_url: "http://www.omdbapi.com/"

config :scraper, Moview.Scraper.Scheduler,
  jobs: [
    # Every Friday
    {"0 5 * * FRI", {Moview.Scraper, :scrape, []}}
  ]
