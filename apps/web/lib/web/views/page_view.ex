defmodule Moview.Web.PageView do
  use Moview.Web, :view
  import Moview.Web.LayoutView, only: [page_title: 0, page_title: 1]


  def render("meta.movie.html", %{movie: %{data: data}}) do
    title =
      case Map.get(data, :title) do
        nil -> ""
        title -> title
      end

    ~E{
      <title><%= page_title(title) %></title>
      <meta name="description" content="TODO">
    }
  end

  def render("meta.movies.html", _) do
    ~E{
      <title><%= page_title() %></title>
      <meta name="description" content="See movies showing in cinemas across Nigeria">
    }
  end

  def render("meta.cinemas.html", _) do
    ~E{
      <title><%= page_title("Cinemas") %></title>
      <meta name="description" content="Cinemas in Nigeria">
    }
  end

  def synopsis(%{data: %{synopsis: synopsis}}) do
    case String.length(synopsis) > 100 do
      false -> String.replace_suffix(synopsis, "...", "")
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
