defmodule Moview.ScraperTest do
  use ExUnit.Case
  doctest Moview.Scraper

  test "greets the world" do
    assert Moview.Scraper.hello() == :world
  end
end
