defmodule Moview.Web.PageView do
  use Moview.Web, :view


  def synopsis(%{data: %{synopsis: synopsis}}) do
    case String.length(synopsis) > 100 do
      false -> String.replace(synopsis, "...", "")
       true -> String.slice(synopsis, 0..96) <> "..."
    end
  end
  def synopsis(_), do: ""

  def movie_url(_, %{data: %{slug: nil}}), do: "#"
  def movie_url(_, %{data: %{slug: ""}}), do: "#"
  def movie_url(conn, %{data: %{slug: slug}}) do
    page_path(conn, :movie, slug)
  end
end
