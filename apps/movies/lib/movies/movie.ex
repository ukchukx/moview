defmodule Moview.Movies.Movie do
  @moduledoc """
  All movie, rating and genre functions return {:ok, result} when successful else {:error, reason/changeset}
  """
  alias Moview.Movies.Movie.Impl


  def slug_generator(title, id) when is_integer(id) and is_binary(title) do
    id_str = "-#{Ruid.to_string(id)}"

    title
    |> String.downcase
    |> remove_unwanted_chars
    |> String.replace_trailing("-", "")
    |> Kernel.<>(id_str)
  end
  def slug_generator(title, _), do: title

  @spec remove_unwanted_chars(text :: String.t) :: String.t
  defp remove_unwanted_chars(text) do
    text
    |> String.replace(~r/([^a-z0-9])+/, to_string([?-]))
    |> String.trim(<<?->>)
  end

  #
  # Movies
  #

  def create_movie(%{rating: _, genres: _} = params) do
    Impl.create_movie(params)
  end

  def update_movie(id, params) do
    Impl.update_movie(id, params)
  end

  def get_movie(id) do
    Impl.get_movie(id)
  end

  def get_movie_by_slug(slug) do
    Impl.get_movie_by_slug(slug)
  end

  def get_movies do
    Impl.get_movies()
  end

  def delete_movie(movie) do
    Impl.delete_movie(movie)
  end

  def delete_movies do
    Impl.delete_movies()
  end

  #
  # Genres
  #

  def create_genre(%{name: _} = params) do
    Impl.create_genre(params)
  end

  def update_genre(id, %{name: _} = params) do
    Impl.update_genre(id, params)
  end

  def get_genre(id) do
    Impl.get_genre(id)
  end

  def get_genre_by_name(name) do
    Impl.get_genre_by_name(name)
  end

  def get_genres do
    Impl.get_genres()
  end

  def delete_genre(genre) do
    Impl.delete_genre(genre)
  end

  def delete_genres do
    Impl.delete_genres()
  end

  #
  # Ratings
  #


  def create_rating(%{name: _} = params) do
    Impl.create_rating(params)
  end

  def update_rating(id, %{name: _} = params) do
    Impl.update_rating(id, params)
  end

  def get_rating(id) do
    Impl.get_rating(id)
  end

  def get_rating_by_name(name) do
    Impl.get_rating_by_name(name)
  end

  def get_ratings do
    Impl.get_ratings()
  end

  def delete_rating(rating) do
    Impl.delete_rating(rating)
  end

  def delete_ratings do
    Impl.delete_ratings()
  end


  #
  # General API operations
  #

  def get_state, do: Impl.get_state()

  def clear_state, do: Impl.clear_state()

  def init, do: Impl.init()

end
