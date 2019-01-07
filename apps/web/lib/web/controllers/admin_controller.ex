defmodule Moview.Web.AdminController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie, Schedule}
  alias Moview.Web.Cache
  alias Moview.Scraper.{Common, Utils}

  def movies(conn, _) do
    {:ok, movies} = Movie.get_movies()
    movies = Enum.map(movies, fn %{id: id} = movie ->
      {:ok, schedules} = Cache.get_schedules(id)
      Map.put(movie, :schedules, schedules)
    end)
    {:ok, cinemas} = Cinema.get_cinemas()
    render conn, "movies.html", movies: movies, cinemas: cinemas
  end

  def refresh(conn, _) do
    Cache.refresh_schedules()
    redirect(conn, to: Routes.page_path(conn, :movies))
  end

  def catch_all(conn, _) do
    redirect(conn, to: Routes.admin_path(conn, :movies))
  end

  def create_movie(conn, %{"title" => title}) do
    {:ok, movies} = Movie.get_movies()

    case Utils.get_movie_details(title) do
      {:error, _} -> nil

      {:ok, %{title: details_title, poster: poster, stars: _} = details} ->
        Enum.filter(movies, fn
          %{data: %{title: ^details_title, poster: ^poster}} -> true
          _ -> false
        end)
        |> case do
          [] ->
            case Movie.create_movie(details) do
              {:ok, movie} -> movie
              _ -> nil
            end

          [movie|_] -> movie
        end
    end

    redirect(conn, to: Routes.admin_path(conn, :movies))
  end

  def add_movie(conn, _) do
    conn
  end

  def delete_movie(conn, %{"movie_id" => movie_id}) do
    Movie.delete_movie(movie_id)
    Cache.refresh_schedules()
    redirect(conn, to: Routes.admin_path(conn, :movies))
  end

  def delete_schedule(conn, %{"schedule_id" => schedule_id}) do
    Schedule.delete_schedule(schedule_id)
    Cache.refresh_schedules()
    redirect(conn, to: Routes.admin_path(conn, :movies))
  end

  def clear_schedules(conn, %{"movie_id" => movie_id}) do
    {:ok, schedules} = Schedule.get_schedules_by_movie(movie_id)
    Enum.each(schedules, fn schedule -> Schedule.delete_schedule(schedule) end)
    Cache.refresh_schedules()
    redirect(conn, to: Routes.admin_path(conn, :movies))
  end

  def add_schedule(conn, %{"type" => t, "cinema_id" => c, "movie_id" => m, "time_string" => s}) do
    case byte_size(s) do
      0 ->
        redirect(conn, to: Routes.admin_path(conn, :movies))
      _ ->
        s
        |> Common.expand_time_string
        |> Common.get_schedule_params(c, m, t)
        |> Enum.each(&Schedule.create_schedule/1)

        Cache.refresh_schedules()
    end

    redirect(conn, to: Routes.admin_path(conn, :movies))
  end
end
