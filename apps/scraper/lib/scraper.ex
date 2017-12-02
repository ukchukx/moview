defmodule Moview.Scraper do
  require Logger
  alias Moview.Movies.{Movie, Schedule}
  alias Moview.Scraper.{Genesis, Filmhouse}

  def scrape do
    [Genesis, Filmhouse]
    |> Enum.each(fn module ->
      %{delete: deletion_list, create: creation_list} =
        module.scrape
        |> List.flatten
        |> Enum.reduce(%{delete: [], create: []}, fn map, acc ->
          deletes = acc.delete ++ map.delete
          creates = acc.create ++ map.create
          %{delete: deletes, create: creates}
        end)

      Logger.info "Deleting stale schedules..."
      Enum.each(deletion_list, &Schedule.delete_schedule/1)
      Logger.info "Creating new schedules..."
      Enum.each(creation_list, &Schedule.create_schedule/1)
    end)

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
