defmodule Moview.Scraper.Filmhouse do
  require Logger
  alias Moview.Movies.Cinema

  def scrape do
    Logger.info "Begin scraping Filmhouse Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Filmhouse Cinemas")
    Enum.map(cinemas, &__MODULE__.Impl.do_scrape([&1]))
  end
end

