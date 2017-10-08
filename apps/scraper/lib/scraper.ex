defmodule Moview.Scraper do
  require Logger
  alias Moview.Movies.{Movie, Schedule}

  def scrape do
    %{delete: deletion_candidates, create: new_schedule_params} =
      [Moview.Scraper.Genesis,
       Moview.Scraper.Filmhouse,
       Moview.Scraper.Silverbird]
      |> Enum.map(&(&1.scrape()))
      |> List.flatten
      |> Enum.reduce(%{delete: [], create: []}, fn map, acc ->
        deletes = acc.delete ++ map.delete
        creates = acc.create ++ map.create
        %{delete: deletes, create: creates}
      end)

    Logger.info "Done scraping. Deleting stale schedules..."
    Enum.each(deletion_candidates, &Schedule.delete_schedule/1)
    Logger.info "Done deleting stale schedules. Creating new schedules..."
    Enum.each(new_schedule_params, &Schedule.create_schedule/1)

    # Remove movies without schedules
    Logger.info "Will now remove movies without schedules..."
    schedules = Schedule.get_schedules() |> elem(1)
    Movie.get_movies()
    |> elem(1)
    |> Enum.filter(fn %{id: id} -> Enum.find(schedules, fn %{movie_id: mid} -> mid == id end) == nil end)
    |> Enum.each(fn movie ->
      Movie.delete_movie(movie)
      Logger.info "Deleted #{movie.data.title}"
    end)
    Logger.info "Finished."
  end
end
