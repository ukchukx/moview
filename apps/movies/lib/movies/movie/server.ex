defmodule Moview.Movies.Movie.Server do
  use GenServer

  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating
  alias Moview.Movies.Repo

  def start_link(state \\ %{movies: [], genres: [], ratings: []}) do
    GenServer.start_link(__MODULE__, state, name: {:global, :movie_service})
  end

  def init(state) do
    send(self(), :init_store)
    {:ok, state}
  end

  def handle_call({:create_movie, %Movie{} = movie}, _from, %{movies: movies} = state) do
    case Repo.insert!(movie) do
      {:ok, movie} ->
        {:reply, {:ok, movie}, %{state | movies: [movie | movies]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_movie, %Movie{id: id} = movie}, _from,%{movies: movies} = state) do
    case Repo.update!(movie) do
      {:ok, movie} ->
        {:reply, {:ok, movie}, %{state | movies: [movie | Enum.filter(movies, &(&1.id != id))]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end


  def handle_call({:get_movie, [id: id]}, _from, %{movies: movies} = state) do
    case Enum.find(movies, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        {:reply, {:ok, movie}, state}
    end
  end

  def handle_call({:get_movies}, _from, %{movies: movies} = state) do
    {:reply, {:ok, movies}, state}
  end

  def handle_call({:get_movie, [slug: slug]}, _from, %{movies: movies} = state) do
    case Enum.find(movies, &(&1.data.slug == slug)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        {:reply, {:ok, movie}, state}
    end
  end

  def handle_call({:delete_movie, [id: id]}, _from, %{movies: movies} = state) do
    case Enum.find(movies, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      movie ->
        Repo.delete!(movie)
        {:reply, {:ok, movie}, %{state | movies: Enum.filter(movies, &(&1.id != id))}}
    end
  end

  def handle_call({:create_genre, %Genre{} = genre}, _from, %{genres: genres} = state) do
    case Repo.insert!(genre) do
      {:ok, genre} ->
        {:reply, {:ok, genre}, %{state | genres: [genre | genres]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_genre, %Genre{id: id} = genre}, _from, %{genres: genres} = state) do
    case Repo.update!(genre) do
      {:ok, genre} ->
        {:reply, {:ok, genre}, %{state | genres: [genre | Enum.filter(genres, &(&1.id != id))]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end


  def handle_call({:get_genre, [id: id]}, _from, %{genres: genres} = state) do
    case Enum.find(genres, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      genre ->
        {:reply, {:ok, genre}, state}
    end
  end

  def handle_call({:get_genres}, _from, %{genres: genres} = state) do
    {:reply, {:ok, genres}, state}
  end

  def handle_call({:delete_genre, [id: id]}, _from, %{genres: genres} = state) do
    case Enum.find(genres, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      genre ->
        Repo.delete!(genre)
        {:reply, {:ok, genre}, %{state | genres: Enum.filter(genres, &(&1.id != id))}}
    end
  end

  def handle_call({:create_rating, %Genre{} = rating}, _from, %{ratings: ratings} = state) do
    case Repo.insert!(rating) do
      {:ok, rating} ->
        {:reply, {:ok, rating}, %{state | ratings: [rating | ratings]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_rating, %Genre{id: id} = rating}, _from, %{ratings: ratings} = state) do
    case Repo.update!(rating) do
      {:ok, rating} ->
        {:reply, {:ok, rating}, %{state | ratings: [rating | Enum.filter(ratings, &(&1.id != id))]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end


  def handle_call({:get_rating, [id: id]}, _from, %{ratings: ratings} = state) do
    case Enum.find(ratings, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      rating ->
        {:reply, {:ok, rating}, state}
    end
  end

  def handle_call({:get_ratings}, _from, %{ratings: ratings} = state) do
    {:reply, {:ok, ratings}, state}
  end

  def handle_call({:delete_rating, [id: id]}, _from, %{ratings: ratings} = state) do
    case Enum.find(ratings, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      rating ->
        Repo.delete!(rating)
        {:reply, {:ok, rating}, %{state | ratings: Enum.filter(ratings, &(&1.id != id))}}
    end
  end


  def handle_info(:init_store, %{movies: _, genres: _, ratings: _} = state) do
    movies = Repo.all(Movie)
    genres = Repo.all(Genre)
    ratings = Repo.all(Rating)

    {:noreply, %{movies: movies, genres: genres, ratings: ratings}}
  end

end
