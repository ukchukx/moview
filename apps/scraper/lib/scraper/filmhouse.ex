defmodule Moview.Scraper.Filmhouse do
  @behaviour Moview.Scraper

  def scrape, do: Moview.Scraper.Common.generic_scrape_fun("Filmhouse Cinemas", __MODULE__.Impl)
end

