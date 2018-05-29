defmodule Moview.Scraper.Silverbird do
  @behaviour Moview.Scraper

  def scrape, do: Moview.Scraper.Common.generic_scrape_fun("Silverbird Cinemas", __MODULE__.Impl)
end
