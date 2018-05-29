defmodule Moview.Scraper.Ozone do
  @behaviour Moview.Scraper

  def scrape, do: Moview.Scraper.Common.generic_scrape_fun("Ozone Cinemas", __MODULE__.Impl)
end
