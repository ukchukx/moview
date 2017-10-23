defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie}
  alias Moview.Web.Cache

  def movies(conn, _) do
    {:ok, movies} = Movie.get_movies()
    render conn, "movies.html", movies: movies
  end

  def catch_all(conn, _) do
    redirect(conn, to: page_path(conn, :movies))
  end

  def movie(conn, %{"slug" => slug} = _) do
    case Movie.get_movie_by_slug(slug) do
      {:error, _} ->
        redirect(conn, to: page_path(conn, :movies))
      {:ok, %{rating_id: rating_id} =  movie} ->
        {:ok, %{data: %{name: rating}}} = Movie.get_rating(rating_id)
        path = page_path(conn, :movie, slug)
        url = page_url(conn, :movie, slug)
        site_url = String.replace_suffix(url, path, "")

        movie =
          movie
          |> Map.get(:data)
          |> Map.put(:id, movie.id)
          |> Map.put(:rating, rating)
          |> Map.put(:url, url)
          |> Map.put(:site_url, site_url)

        {:ok, schedules} = Cache.get_schedules(movie.id)
        render conn, "movie.html", movie: movie, schedules: schedules
    end
  end

  def cinemas(conn, _) do
    {:ok, cinemas} = Cinema.get_cinemas()
    render conn, "cinemas.html", cinemas: cinemas
  end
end
