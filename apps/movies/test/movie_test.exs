defmodule Moview.MovieTest do
  use ExUnit.Case

  alias Moview.Movies.Movie, as: API


  setup %{} do
    on_exit fn -> API.clear_state() end

    API.Impl.init(true)
    {:ok, genre1} = API.create_genre(%{name: "Action"})
    {:ok, genre2} = API.create_genre(%{name: "Thriller"})
    {:ok, %{data: %{name: rating1}}} = API.create_rating(%{name: "PG"})
    {:ok, %{data: %{name: rating2}}} = API.create_rating(%{name: "R"})

    {:ok, movie} =
      %{title: "Action film",
        runtime: 90,
        rating: rating1,
        stars: ["Actor A", "Actor B"],
        genres: ["Action", "Thriller"]} |> API.create_movie

    {:ok,
      movie_params: %{runtime: 60, genres: ["Action", "Thriller"],
        rating: rating2, title: "Another action film", stars: ["Actor A", "Actor C"]},
      movie: movie,
      genres: [genre1, genre2]}
  end

  test "create movie", %{movie_params: %{title: ptitle} = params} do
    {:ok, %{data: %{title: name, slug: slug}, id: id}} = API.create_movie(params)
    assert name == ptitle
    assert String.contains?(slug, "another-action-film")
    assert id
  end

  test "update movie", %{movie: %{id: id, data: %{slug: old_slug}}, movie_params: %{title: ptitle, stars: stars} = params} do
    {:ok, %{id: mid, data: %{title: title, stars: new_stars, slug: new_slug}}} = API.update_movie(id, params)
    refute old_slug == new_slug
    assert title == ptitle
    assert mid == id
    assert new_stars == stars
  end

  test "get a movie", %{movie: %{id: id, data: %{title: name}}} do
    {:ok, %{data: %{title: mname}}} = API.get_movie(id)
    assert mname == name
  end

  test "get movies", %{movie: %{id: id, data: %{title: name}}} do
    {:ok, movies} = API.get_movies()
    assert 1 == Enum.count(movies)

    %{id: mid, data: %{title: mname}} = Enum.at(movies, 0)
    assert mname == name
    assert mid == id
  end

  test "find movie by slug", %{movie: %{data: %{slug: slug}, id: id}} do
    {:ok, %{id: mid}} = API.get_movie_by_slug(slug)
    assert id == mid
    assert {:error, :not_found} == API.get_movie_by_slug("a-random-slug")
  end

  test "delete movie", %{movie: %{id: id} = movie} do
    {:ok, %{id: mid}} = API.delete_movie(movie)
    assert mid == id
    assert {:error, :not_found} == API.get_movie(id)
  end
end


