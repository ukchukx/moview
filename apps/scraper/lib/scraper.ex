defmodule Moview.Scraper do

  def scrape do
    [Moview.Scraper.Genesis,
     Moview.Scraper.Silverbird,
     Moview.Scraper.Filmhouse] |> Enum.each(&(&1.scrape()))
  end
end
