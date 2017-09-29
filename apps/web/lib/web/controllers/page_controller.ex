defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie, Schedule}

  def movies(conn, _) do
    {:ok, movies} = Movie.get_movies()
    render conn, "movies.html", movies: movies
  end

  def catch_all(conn, _) do
    redirect(conn, to: page_path(conn, :movies))
  end

  def movie(conn, %{"slug" => slug} = _) do
    case Movie.get_movie_by_slug(slug) do
      {:error, _} -> redirect(conn, to: page_path(conn, :movies))
      {:ok, %{rating_id: rating_id, data: %{title: title}} =  movie} ->
        {:ok, %{data: %{name: rating}}} = Movie.get_rating(rating_id)
        movie =
          movie
          |> Map.get(:data)
          |> Map.put(:id, movie.id)
          |> Map.put(:rating, rating)
        schedules = []
        render conn, "movie.html", movie: movie, schedules: schedules
    end
  end

  def cinemas(conn, _) do
    {:ok, cinemas} = Cinema.get_cinemas()
    render conn, "cinemas.html", cinemas: cinemas
  end
end
