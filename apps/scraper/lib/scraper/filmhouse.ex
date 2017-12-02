defmodule Moview.Scraper.Filmhouse do
  require Logger
  alias Moview.Movies.Cinema

  def scrape do
    Logger.info "Begin scraping Filmhouse Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Filmhouse Cinemas")
    tasks = Enum.map(cinemas, fn cinema ->
      Task.async(fn -> __MODULE__.Impl.do_scrape([cinema]) end)
    end)
    Enum.map(tasks, &Task.await/1)
  end
end

