defmodule Moview.Web.AdminView do
  use Moview.Web, :view

  def cinema_name(cinema), do: Moview.Movies.Cinema.cinema_name(cinema)
end
