defmodule Moview.Web.AdminController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie, Schedule}
  alias Moview.Web.Cache

  def movies(conn, _) do
    {:ok, movies} = Movie.get_movies()
    movies = Enum.map(movies, fn %{id: id} = movie ->
      {:ok, schedules} = Cache.get_schedules(id)
      Map.put(movie, :schedules, schedules)
    end)
    render conn, "movies.html", movies: movies
  end

  def catch_all(conn, _) do
    redirect(conn, to: admin_path(conn, :movies))
  end

  def add_movie(conn, _) do
    conn
  end

  def delete_movie(conn, %{"movie_id" => movie_id}) do
    Movie.delete_movie(movie_id)
    Cache.refresh_schedules()
    redirect(conn, to: admin_path(conn, :movies))
  end

  def delete_schedule(conn, %{"schedule_id" => schedule_id}) do
    Schedule.delete_schedule(schedule_id)
    Cache.refresh_schedules()
    redirect(conn, to: admin_path(conn, :movies))
  end

  def clear_schedules(conn, %{"movie_id" => movie_id}) do
    {:ok, schedules} = Schedule.get_schedules_by_movie(movie_id)
    Enum.each(schedules, fn schedule -> Schedule.delete_schedule(schedule) end)
    Cache.refresh_schedules()
    redirect(conn, to: admin_path(conn, :movies))
  end

  def add_schedule(conn, _) do
    conn
  end
end
