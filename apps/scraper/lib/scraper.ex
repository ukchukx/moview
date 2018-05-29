defmodule Moview.Scraper do
  require Logger
  alias Moview.Movies.{Cinema, Movie, Schedule}
  alias Moview.Scraper.{Genesis, Filmhouse, Ozone, Silverbird}

  @callback scrape() :: map

  def run do
    [Genesis, Filmhouse, Ozone, Silverbird]
    |> Enum.map(fn module ->
      Task.async(fn ->  
        Logger.info "Run scraper for #{inspect module}..."
        module.scrape
        Logger.info "Done scraping #{inspect module}"
      end)
    end)
    |> Enum.each(&Task.await(&1, 300_000))

    # Remove movies without schedules
    Logger.info "Remove movies without schedules..."
    schedules = Schedule.get_schedules() |> elem(1)
    Movie.get_movies  
    |> elem(1)
    |> Enum.filter(fn %{id: id} -> Enum.find(schedules, fn %{movie_id: mid} -> mid == id end) == nil end)
    |> Enum.each(fn movie ->
      Movie.delete_movie(movie)
      Logger.debug "Deleted #{movie.data.title}"
    end)
    Logger.info "Finished."
  end
end
