defmodule Moview.Scraper.Genesis do
  @behaviour Moview.Scraper

  require Logger
  alias Moview.Movies.Cinema

  def scrape do
    Logger.info "Begin scraping Genesis Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Genesis Cinemas")

    cinemas
    # Ignore cinemas without urls
    |> Enum.filter(fn
      %{data: %{url: ""}} -> false
      nil -> false
      _ -> true
    end)
    |>__MODULE__.Impl.do_scrape
  end
end

