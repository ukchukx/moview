defmodule Moview.Scraper.Genesis do
  require Logger
  alias Moview.Movies.Cinema

  def scrape do
    Logger.info "Begin scraping Genesis Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Genesis Cinemas")
    Enum.map(cinemas, &__MODULE__.Impl.do_scrape([&1]))
  end
end

