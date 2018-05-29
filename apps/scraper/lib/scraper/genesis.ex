defmodule Moview.Scraper.Genesis do
  @behaviour Moview.Scraper

  def scrape, do: Moview.Scraper.Common.generic_scrape_fun("Genesis Cinemas", __MODULE__.Impl)
end

