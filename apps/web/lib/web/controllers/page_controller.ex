defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  alias Moview.Movies.{Cinema, Movie, Schedule}

  def movies(conn, _params) do
    {:ok, _movies} = Movie.get_movies()
    render conn, "movies.html", title: site_name()
  end

  def movie(conn, %{"slug" => _slug} = _) do
    render conn, "movies.html"
  end

  def cinemas(conn, _) do
    {:ok, cinemas} = Cinema.get_cinemas()
    render conn, "cinemas.html", cinemas: cinemas, title: "Cinemas | #{site_name()}"
  end

  defp site_name, do: "Moview"
end
