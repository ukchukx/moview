defmodule Moview.Movies.Movie.Impl do
  import Ecto.Query
  import Moview.Movies.BaseSchema, only: [to_map: 1]

  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating
  alias Moview.Movies.Repo

  @service_name Application.get_env(:movies, :services)[:movie]

  def clear_state do
    delete_movies()
    delete_ratings()
    delete_genres()
  end

  def get_state do
    GenServer.call(@service_name, :which_state)
  end

  def init(link? \\ false) do
    state = init_state()
    case link? do
      true ->
        __MODULE__.Server.start_link(state)
      false ->
        __MODULE__.Server.start(state)
    end
  end

  defp init_state do
    movies = Repo.all(Movie) |> to_map
    genres = Repo.all(Genre) |> to_map
    ratings = Repo.all(Rating) |> to_map
    %{movies: movies, genres: genres, ratings: ratings}
  end

  def create_movie(%{rating: rating_name, genres: genres} = params) do
    # Get the id of the rating with the supplied name
    rating_id =
      case get_rating_by_name(rating_name) do
        {:ok, %Rating{id: id}} ->
          id
        {:error, _} -> # Does not exist, so we create it
          {:ok, %Rating{id: id}} = create_rating(%{name: rating_name})
          id
      end

    # Look for uncreated genres & create them
    {:ok, genre_list} = get_genres()
    genre_name_list = Enum.map(genre_list, &(String.downcase(&1.data.name)))
    genre_list =
      genres
      # Split the supplied genres into ones that have been created & ones that have not
      |> Enum.split_with(fn g -> String.downcase(g) in genre_name_list end)
      # Get the ones that have not been created
      |> elem(1)
      # Create them
      |> Enum.map(fn g ->
        {:ok, genre} = create_genre(%{name: g})
        genre
      end)
      # Concat list of created genres with genre_list
      |> Enum.into(genre_list)

    # Update params with the rating id
    params =
      params
      |> Map.put(:rating_id, rating_id)

    case Movie.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        case Repo.insert!(changeset) do
          {:error, changeset} ->
            {:error, changeset}
          movie ->
            # Associate genres
            genres = Enum.map(genres, &String.downcase/1)
            movie_genres = Enum.filter(genre_list, fn genre -> String.downcase(genre.data.name) in genres end)
            Movie.associate_genres(movie, movie_genres)
            GenServer.cast(@service_name, {:save_movie, movie})
            {:ok, movie}
        end
      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}
    end
  end

  def update_movie(id, params) do
    case get_movie(id) do
      {:ok, movie} ->
        case Movie.changeset(movie, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.update!(changeset) do
              {:error, changeset} ->
                {:error, changeset}
              movie ->
                GenServer.cast(@service_name, {:save_movie, movie})
                {:ok, movie}
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get_movie_by_slug(slug) do
    case GenServer.call(@service_name, {:get_movie, [slug: slug]}) do
      {:error, :not_found} = err ->
        case Repo.one(from r in Movie, where: fragment("data->>'slug' = ?", ^slug)) do
          nil -> err
          movie ->
            GenServer.cast(@service_name, {:save_movie, movie})
            {:ok, movie}
        end
      {:ok, movie} ->
        {:ok, movie}
    end
  end

  def get_movie(id) do
    case GenServer.call(@service_name, {:get_movie, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(Movie, id) do
          nil -> err
          movie ->
            GenServer.cast(@service_name, {:save_movie, movie})
            {:ok, movie}
        end
      {:ok, rating} -> {:ok, rating}
    end
  end

  def get_movies do
    GenServer.call(@service_name, {:get_movies})
    case GenServer.call(@service_name, {:get_movies}) do
      {:ok, []} ->
        case Repo.all(Movie) do
          [] ->
            {:ok, []}
          movies ->
            Enum.each(movies, fn movie -> GenServer.cast(@service_name, {:save_movie, movie}) end)
            {:ok, movies}
        end
      {:ok, _movies} = res -> res
    end
  end

  def delete_movies do
    GenServer.cast(@service_name, {:delete_movies})
    Repo.delete_all(Movie)
  end

  def delete_movie(%Movie{id: id} = movie) do
    GenServer.cast(@service_name, {:delete_movie, [id: id]})
    {:ok, Repo.delete!(movie)}
  end


  def create_rating(%{name: name} = params) do
    case get_rating_by_name(name) do
      {:ok, rating} ->
        {:ok, rating}
      {:error, :not_found} ->
        case Rating.changeset(params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.insert!(changeset) do
              {:error, changeset} ->
                {:error, changeset}
              rating ->
                GenServer.cast(@service_name, {:save_rating, rating})
                {:ok, rating}
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
    end
  end

  def update_rating(id, %{name: new_name} = params) do
    case get_rating(id) do
      {:ok, rating} ->
        case Rating.changeset(rating, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case get_rating_by_name(new_name) do
              {:ok, _} ->
                {:error, :name_exists}
              {:error, :not_found} ->
                case Repo.update!(changeset) do
                  {:error, changeset} ->
                    {:error, changeset}
                  rating ->
                    GenServer.cast(@service_name, {:save_rating, rating})
                    {:ok, rating}
                end
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get_ratings do
    case GenServer.call(@service_name, {:get_ratings}) do
      {:ok, []} ->
        case Repo.all(Rating) do
          [] ->
            {:ok, []}
          ratings ->
            Enum.each(ratings, fn rating -> GenServer.cast(@service_name, {:save_rating, rating}) end)
            {:ok, ratings}
        end
      {:ok, _ratings} = res -> res
    end
  end

  def get_rating(id) do
    case GenServer.call(@service_name, {:get_rating, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(Rating, id) do
          nil -> err
          rating ->
            GenServer.cast(@service_name, {:save_rating, rating})
            {:ok, rating}
        end
      {:ok, rating} ->
        {:ok, rating}
    end
  end

  def get_rating_by_name(name) do
    case GenServer.call(@service_name, {:get_rating, [name: name]}) do
      {:error, :not_found} = err ->
        lname = String.downcase(name)
        case Repo.one(from r in Rating, where: fragment("lower(data->>'name') = ?", ^lname)) do
          nil -> err
          rating ->
            GenServer.cast(@service_name, {:save_rating, rating})
            {:ok, rating}
        end
      {:ok, rating} ->
        {:ok, rating}
    end
  end

  def delete_rating(%Rating{id: id} = rating) do
    GenServer.cast(@service_name, {:delete_rating, [id: id]})
    {:ok, Repo.delete!(rating)}
  end

  def delete_ratings do
    GenServer.cast(@service_name, {:delete_ratings})
    Repo.delete_all(Rating)
  end


  def create_genre(%{name: name} = params) do
    case get_genre_by_name(name) do
      {:ok, genre} ->
        {:ok, genre}
      {:error, :not_found} ->
        case Genre.changeset(params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.insert!(changeset) do
              {:error, changeset} ->
                {:error, changeset}
              genre ->
                GenServer.cast(@service_name, {:save_genre, genre})
                {:ok, genre}
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
    end
  end

  def update_genre(id, %{name: new_name} = params) do
    case get_genre(id) do
      {:ok, genre} ->
        case Genre.changeset(genre, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case get_genre_by_name(new_name) do
              {:ok, _} ->
                {:error, :name_exists}
              {:error, :not_found} ->
                case Repo.update!(changeset) do
                  {:error, changeset} ->
                    {:error, changeset}
                  genre ->
                    GenServer.cast(@service_name, {:save_genre, genre})
                    {:ok, genre}
                end
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get_genre(id) do
    case GenServer.call(@service_name, {:get_genre, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(Genre, id) do
          nil -> err
          genre ->
            GenServer.cast(@service_name, {:save_genre, genre})
            {:ok, genre}
        end
      {:ok, genre} ->
        {:ok, genre}
    end
  end

  def get_genre_by_name(name) do
    case GenServer.call(@service_name, {:get_genre, [name: name]}) do
      {:error, :not_found} = err ->
        lname = String.downcase(name)
        case Repo.one(from r in Genre, where: fragment("lower(data->>'name') = ?", ^lname)) do
          nil -> err
          genre ->
            GenServer.cast(@service_name, {:save_genre, genre})
            {:ok, genre}
        end
      {:ok, genre} ->
        {:ok, genre}
    end
  end

  def get_genres do
    case GenServer.call(@service_name, {:get_genres}) do
      {:ok, []} ->
        case Repo.all(Genre) do
          [] ->
            {:ok, []}
          genres ->
            Enum.each(genres, fn genre -> GenServer.cast(@service_name, {:save_genre, genre}) end)
            {:ok, genres}
        end
      {:ok, _genres} = res -> res
    end
  end

  def delete_genre(%Genre{id: id} = genre) do
    GenServer.cast(@service_name, {:delete_genre, [id: id]})
    {:ok, Repo.delete!(genre)}
  end

  def delete_genres do
    GenServer.cast(@service_name, {:delete_genres})
    Repo.delete_all(Genre)
  end

  defmodule Server do
    use GenServer

    @service_name Application.get_env(:movies, :services)[:movie]

    def start(state \\ %{}) do
      GenServer.start(__MODULE__, state, name: @service_name)
    end

    def start_link(state \\ %{}) do
      GenServer.start_link(__MODULE__, state, name: @service_name)
    end


    def init(state) do
      {:ok, state}
    end

    def handle_call(:which_state, _, state), do: {:reply, state, state}

    def handle_call({:get_movie, [id: id]}, _, %{movies: movies} = state) do
      case Map.get(movies, id) do
        nil ->
          {:reply, {:error, :not_found}, state}
        movie ->
          {:reply, {:ok, movie}, state}
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

    def handle_call({:get_rating, [id: id]}, _, %{ratings: ratings} = state) do
      case Map.get(ratings, id) do
        nil ->
          {:reply, {:error, :not_found}, state}
        rating ->
          {:reply, {:ok, rating}, state}
      end
    end

    def handle_call({:get_movie, [slug: slug]}, _, %{movies: movies} = state) do
      case Map.values(movies) |> Enum.find(&(&1.data.slug == slug)) do
        nil ->
          {:reply, {:error, :not_found}, state}
        movie ->
          {:reply, {:ok, movie}, state}
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

    def handle_call({:get_rating, [name: name]}, _, %{ratings: ratings} = state) do
      name = String.downcase(name)
      case Map.values(ratings) |> Enum.find(&(String.downcase(&1.data.name) == name)) do
        nil ->
          {:reply, {:error, :not_found}, state}
        rating ->
          {:reply, {:ok, rating}, state}
      end
    end

    def handle_call({:get_movies}, _, %{movies: movies} = state) do
      {:reply, {:ok, Map.values(movies)}, state}
    end

    def handle_call({:get_genres}, _, %{genres: genres} = state) do
      {:reply, {:ok, Map.values(genres)}, state}
    end

    def handle_call({:get_ratings}, _, %{ratings: ratings} = state) do
      {:reply, {:ok, Map.values(ratings)}, state}
    end


    def handle_cast({:save_movie, %{id: id} = movie}, %{movies: movies} = state) do
      {:noreply, %{state | movies: Map.put(movies, id, movie)}}
    end

    def handle_cast({:save_genre, %{id: id} = genre}, %{genres: genres} = state) do
      {:noreply, %{state | genres: Map.put(genres, id, genre)}}
    end

    def handle_cast({:save_rating, %{id: id} = rating}, %{ratings: ratings} = state) do
      {:noreply, %{state | ratings: Map.put(ratings, id, rating)}}
    end

    def handle_cast({:delete_movie, [id: id]}, %{movies: movies} = state) do
      {:noreply, %{state | movies: Map.delete(movies, id)}}
    end

    def handle_cast({:delete_genre, [id: id]}, %{genres: genres} = state) do
      {:noreply, %{state | genres: Map.delete(genres, id)}}
    end

    def handle_cast({:delete_rating, [id: id]}, %{ratings: ratings} = state) do
      {:noreply, %{state | ratings: Map.delete(ratings, id)}}
    end

    def handle_cast({:delete_movies}, state) do
      {:noreply, %{state | movies: %{}}}
    end

    def handle_cast({:delete_genres}, state) do
      {:noreply, %{state | genres: %{}}}
    end

    def handle_cast({:delete_ratings}, state) do
      {:noreply, %{state | ratings: %{}}}
    end
  end
end
