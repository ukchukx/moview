defmodule Moview.Scraper do
  alias Moview.Movies.{Movie, Schedule}

  def scrape do
    [Moview.Scraper.Genesis,
     Moview.Scraper.Silverbird,
     Moview.Scraper.Filmhouse] |> Enum.each(&(&1.scrape()))

    # Remove movies without schedules
    schedules = Schedule.get_schedules() |> elem(1)
    orphaned_movies =
      Movie.get_movies()
      |> elem(1)
      |> Enum.filter(fn %{id: id} -> Enum.find(schedules, fn %{movie_id: mid} -> mid == id end) == nil end)

    Enum.each(orphaned_movies, fn movie ->
      Movie.delete_movie(movie)
      Logger.info "Deleted #{movie.data.title}"
    end)
  end
end
