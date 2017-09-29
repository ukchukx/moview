defmodule Moview.Scraper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :scraper,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpotion],
      mod: {Moview.Scraper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:movies, in_umbrella: true},
     {:floki, "~> 0.18.0"},
     {:httpotion, "~> 3.0.2"},
     {:poison, "~> 3.1"},
     {:quantum, ">= 2.1.0"},
     {:timex, "~> 3.0"}
    ]
  end
end
