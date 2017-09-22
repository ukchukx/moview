defmodule Moview.Movies.Movie.Server do
  use GenServer

  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating
  alias Moview.Movies.Repo

  @service_name {:global, Application.get_env(:movies, :services)[:movie] }

  def start_link(state \\ %{movies: [], genres: [], ratings: []}) do
    GenServer.start_link(__MODULE__, state, name: @service_name)
  end

  def init(state) do
    send(self(), :init_store)
    {:ok, state}
  end

  def handle_call({:create_movie, %Ecto.Changeset{valid?: true} = movie_changeset}, _from, %{movies: movies} = state) do
    case Repo.insert!(movie_changeset) do
      movie ->
        {:reply, {:ok, movie}, %{state | movies: [movie | movies]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_movie, %Ecto.Changeset{valid?: true} = movie_changeset}, _from,%{movies: movies} = state) do
    case Repo.update!(movie_changeset) do
      %{id: id} = movie ->
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

  def handle_call({:create_genre, %Ecto.Changeset{valid?: true} = genre_changeset}, _from, %{genres: genres} = state) do
    case Repo.insert!(genre_changeset) do
      genre ->
        {:reply, {:ok, genre}, %{state | genres: [genre | genres]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_genre, %Ecto.Changeset{valid?: true} = genre_changeset}, _from, %{genres: genres} = state) do
    case Repo.update!(genre_changeset) do
      %{id: id} = genre ->
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

  def handle_call({:get_genre, [name: name]}, _from, %{genres: genres} = state) do
    name = String.downcase(name)
    case Enum.find(genres, &(String.downcase(&1.data.name) == name)) do
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
        {:reply, {:ok, genre}, %{state | genres: Enum.filter(genres, &(&1.id != genre.id))}}
    end
  end

  def handle_call({:create_rating, %Ecto.Changeset{valid?: true} = rating_changeset}, _from, %{ratings: ratings} = state) do
    case Repo.insert!(rating_changeset) do
      rating ->
        {:reply, {:ok, rating}, %{state | ratings: [rating | ratings]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_rating, %Ecto.Changeset{valid?: true} = rating_changeset}, _from, %{ratings: ratings} = state) do
    case Repo.update!(rating_changeset) do
      %{id: id} = rating ->
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

  def handle_call({:get_rating, [name: name]}, _from, %{ratings: ratings} = state) do
    name = String.downcase(name)
    case Enum.find(ratings, &(String.downcase(&1.data.name) == name)) do
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
        {:reply, {:ok, rating}, %{state | ratings: Enum.filter(ratings, &(&1.id != rating.id))}}
    end
  end


  def handle_info(:init_store, %{movies: _, genres: _, ratings: _}) do
    movies = Repo.all(Movie)
    genres = Repo.all(Genre)
    ratings = Repo.all(Rating)

    {:noreply, %{movies: movies, genres: genres, ratings: ratings}}
  end

end
