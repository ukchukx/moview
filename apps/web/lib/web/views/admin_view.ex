defmodule Moview.Web.AdminView do
  use Moview.Web, :view

  def cinema_name(cinema), do: Moview.Movies.Cinema.cinema_name(cinema)

  def movie_url(_, %{data: %{slug: nil}}), do: "#"
  def movie_url(_, %{data: %{slug: ""}}), do: "#"
  def movie_url(conn, %{data: %{slug: slug}}), do: Routes.page_path(conn, :movie, slug)
end
