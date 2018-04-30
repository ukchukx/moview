defmodule Moview.Scraper.Silverbird do
  @behaviour Moview.Scraper

  def scrape, do: __MODULE__.Impl.scrape()
end
