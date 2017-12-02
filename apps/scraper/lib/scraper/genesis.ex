defmodule Moview.Scraper.Genesis do
  require Logger
  alias Moview.Movies.Cinema

  def scrape do
    Logger.info "Begin scraping Genesis Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Genesis Cinemas")
    tasks = Enum.map(cinemas, fn cinema ->
      Task.async(fn -> __MODULE__.Impl.do_scrape([cinema]) end)
    end)
    Enum.map(tasks, &Task.await/1)
  end
end

