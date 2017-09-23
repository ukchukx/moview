defmodule Moview.Movies.Movie.Server do
  use GenServer

  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating
  alias Moview.Movies.Repo

  @service_name {:global, Application.get_env(:movies, :services)[:movie] }

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: @service_name)
  end

  def init(state) do
    send(self(), :init_store)
    {:ok, state}
  end

  def handle_call(:which_state, _, state), do: {:reply, state, state}

  def handle_call({:create_movie, %Ecto.Changeset{valid?: true} = movie_changeset}, _, %{movies: movies} = state) do
    case Repo.insert!(movie_changeset) do
      %{id: id} = movie ->
        {:reply, {:ok, movie}, %{state | movies: Map.put(movies, id, movie)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_movie, %Ecto.Changeset{valid?: true} = movie_changeset}, _,%{movies: movies} = state) do
    case Repo.update!(movie_changeset) do
      %{id: id} = movie ->
        {:reply, {:ok, movie}, %{state | movies: Map.put(movies, id, movie)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end


  def handle_call({:get_movie, [id: id]}, _, %{movies: movies} = state) do
    case Map.get(movies, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        {:reply, {:ok, movie}, state}
    end
  end

  def handle_call({:get_movies}, _, %{movies: movies} = state) do
    {:reply, {:ok, Map.values(movies)}, state}
  end

  def handle_call({:get_movie, [slug: slug]}, _, %{movies: movies} = state) do
    case Map.values(movies) |> Enum.find(&(&1.data.slug == slug)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        {:reply, {:ok, movie}, state}
    end
  end

  def handle_call({:delete_movie, [id: id]}, _, %{movies: movies} = state) do
    case Map.get(movies, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        {:reply, Repo.delete(movie), %{state | movies: Map.delete(movies, id)}}
    end
  end

  def handle_call({:create_genre, %Ecto.Changeset{valid?: true} = genre_changeset}, _, %{genres: genres} = state) do
    case Repo.insert!(genre_changeset) do
      %{id: id} = genre ->
        {:reply, {:ok, genre}, %{state | genres: Map.put(genres, id, genre)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_genre, %Ecto.Changeset{valid?: true} = genre_changeset}, _, %{genres: genres} = state) do
    case Repo.update!(genre_changeset) do
      %{id: id} = genre ->
        {:reply, {:ok, genre}, %{state | genres: Map.put(genres, id, genre)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:get_genre, [id: id]}, _, %{genres: genres} = state) do
    case Map.get(genres, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      genre ->
        {:reply, {:ok, genre}, state}
    end
  end

  def handle_call({:get_genre, [name: name]}, _, %{genres: genres} = state) do
    name = String.downcase(name)
    case Map.values(genres) |> Enum.find(&(String.downcase(&1.data.name) == name)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      genre ->
        {:reply, {:ok, genre}, state}
    end
  end

  def handle_call({:get_genres}, _, %{genres: genres} = state) do
    {:reply, {:ok, Map.values(genres)}, state}
  end

  def handle_call({:delete_genre, [id: id]}, _, %{genres: genres} = state) do
    case Map.get(genres, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      %{id: id} = genre ->
        {:reply, Repo.delete(genre), %{state | genres: Map.delete(genres, id)}}
    end
  end

  def handle_call({:create_rating, %Ecto.Changeset{valid?: true} = rating_changeset}, _, %{ratings: ratings} = state) do
    case Repo.insert!(rating_changeset) do
      %{id: id} = rating ->
        {:reply, {:ok, rating}, %{state | ratings: Map.put(ratings, id, rating)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_rating, %Ecto.Changeset{valid?: true} = rating_changeset}, _, %{ratings: ratings} = state) do
    case Repo.update!(rating_changeset) do
      %{id: id} = rating ->
        {:reply, {:ok, rating}, %{state | ratings: Map.put(ratings, id, rating)}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end


  def handle_call({:get_rating, [id: id]}, _, %{ratings: ratings} = state) do
    case Map.get(ratings, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      rating ->
        {:reply, {:ok, rating}, state}
    end
  end

  def handle_call({:get_rating, [name: name]}, _, %{ratings: ratings} = state) do
    name = String.downcase(name)
    case Map.values(ratings) |> Enum.find(&(String.downcase(&1.data.name) == name)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      rating ->
        {:reply, {:ok, rating}, state}
    end
  end

  def handle_call({:get_ratings}, _, %{ratings: ratings} = state) do
    {:reply, {:ok, Map.values(ratings)}, state}
  end

  def handle_call({:delete_rating, [id: id]}, _, %{ratings: ratings} = state) do
    case Map.get(ratings, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      %{id: id} = rating ->
        {:reply, Repo.delete(rating), %{state | ratings: Map.delete(ratings, id)}}
    end
  end


  def handle_cast({:delete_movies}, state) do
    Repo.delete_all(Movie)
    {:noreply, %{state | movies: %{}}}
  end

  def handle_cast({:delete_genres}, state) do
    Repo.delete_all(Genre)
    {:noreply, %{state | genres: %{}}}
  end

  def handle_cast({:delete_ratings}, state) do
    Repo.delete_all(Rating)
    {:noreply, %{state | ratings: %{}}}
  end


  def handle_info(:init_store, %{}) do
    movies = Repo.all(Movie) |> to_map
    genres = Repo.all(Genre) |> to_map
    ratings = Repo.all(Rating) |> to_map

    {:noreply, %{movies: movies, genres: genres, ratings: ratings}}
  end

  defp to_map(list) when is_list(list) do
    list
    |> Enum.reduce(%{}, fn resource = %{id: id}, acc ->
      Map.put(acc, id, resource)
    end)
  end

end
