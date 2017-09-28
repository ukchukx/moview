defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie, Schedule}

  def movies(conn, _) do
    {:ok, movies} = Movie.get_movies()
    render conn, "movies.html", movies: movies, title: page_title()
  end

  def catch_all(conn, _) do
    redirect(conn, to: page_path(conn, :movies))
  end

  def movie(conn, %{"slug" => slug} = _) do
    case Movie.get_movie_by_slug(slug) do
      {:error, _} -> redirect(conn, to: page_path(conn, :movies))
      {:ok, %{rating_id: rating_id, data: %{title: title}} =  movie} ->
        {:ok, %{data: %{name: rating}}} = Movie.get_rating(rating_id)
        render conn, "movie.html", movie: movie, rating: rating, title: page_title(title)
    end
    render conn, "movie.html"
  end

  def cinemas(conn, _) do
    {:ok, cinemas} = Cinema.get_cinemas()
    render conn, "cinemas.html", cinemas: cinemas, title: page_title("Cinemas")
  end

  defp page_title, do: site_name()
  defp page_title(string), do: "#{string} | #{site_name()}"

  defp site_name, do: "Moview"
end
