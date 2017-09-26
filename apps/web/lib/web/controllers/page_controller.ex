defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  def movies(conn, _params) do
    render conn, "movies.html"
  end

  def movie(conn, %{"slug" => _slug} = _) do
    render conn, "movies.html"
  end

  def cinemas(conn, _) do
    render conn, "movies.html"
  end
end
