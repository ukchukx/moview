defmodule Moview.Movies.Movie do
  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating

  @service_name {:global, :movie_service}


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
    |> String.strip(?-)
  end


  def get_movie_by_slug(slug) do
    GenServer.call(@service_name, {:get_movie, [slug: slug]})
  end

  def create_movie(%{} = params) do
    :ok
  end

  def create_genre(%{} = params) do
    :ok
  end

  def create_rating(%{} = params) do
    :ok
  end

  def update_movie(id, %{} = params) do
    :ok
  end

  def update_genre(id, %{} = params) do
    :ok
  end

  def update_rating(id, %{} = params) do
    :ok
  end

  def delete_movie(id) do
    GenServer.call(@service_name, {:get_movie, [id: id]})
  end

  def delete_genre(id) do
    GenServer.call(@service_name, {:get_genre, [id: id]})
  end

  def delete_rating(id) do
    GenServer.call(@service_name, {:get_rating, [id: id]})
  end

  def get_movie(id) do
    GenServer.call(@service_name, {:get_movie, [id: id]})
  end

  def get_genre(id) do
    GenServer.call(@service_name, {:get_genre, [id: id]})
  end

  def get_rating(id) do
    GenServer.call(@service_name, {:get_rating, [id: id]})
  end

  def get_movies do
    GenServer.call(@service_name, {:get_movies})
  end

  def get_genres do
    GenServer.call(@service_name, {:get_genres})
  end

  def get_ratings do
    GenServer.call(@service_name, {:get_ratings})
  end

end
