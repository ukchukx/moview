defmodule Moview.Web.PageView do
  use Moview.Web, :view
  import Moview.Web.LayoutView, only: [page_title: 0, site_name: 0, page_title: 1]

  def render("meta.movie.html", %{movie: %{site_url: surl, url: url, title: t, poster: p, synopsis: s}}) do
    pt = page_title(t)
    ~E{
      <title><%= pt %></title>
      <meta name="description" content="<%= s %>">
      <meta property="og:site_name" content="<%= site_name() %>">
      <meta property="og:type" content="website">
      <meta property="og:url" content="<%= url %>">
      <meta property="og:title" content="<%= pt %>">
      <meta property="og:description" content="<%= s %>">
      <meta property="og:image" content="<%= p %>">
      <meta name="twitter:image" content="<%= p %>">
      <meta name="twitter:image" content="<%= p %> poster">
      <meta name="twitter:card" content="summary_large_image">
      <meta name="twitter:url" value="<%= url %>">
      <meta name="twitter:title" value="<%= pt %>">
      <meta name="twitter:domain" value="<%= surl %>">
      <meta name="twitter:description" value="<%= s %>">
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
