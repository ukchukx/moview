defmodule Moview.Movies.Movie.Impl do
  import Ecto.Query

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

  def seed_from_db do
    GenServer.cast(@service_name, {:seed_movies, Repo.all(Movie)})
    GenServer.cast(@service_name, {:seed_genres, Repo.all(Genre)})
    GenServer.cast(@service_name, {:seed_ratings, Repo.all(Rating)})
  end

  def create_movie(params) do
    case get_duplicate(params) do
      nil -> do_create_movie(params)
      movie -> {:ok, movie}
    end
  end

  defp do_create_movie(%{rating: rating_name, genres: genres} = params) do
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

  def movie_exists?(%{title: _, stars: _} = params) do
    case get_duplicate(params) do
      nil -> false
      _ -> true
    end
  end

  defp get_duplicate(%{title: title, stars: stars}) do
    {:ok, movies} = get_movies()
    Enum.find(movies, fn
      %{data: %{title: ^title, stars: stars2}} -> list_equals?(stars, stars2)
      _ -> false
    end)
  end

  defp list_equals?(list1, list2) do
    list1
    |> Enum.drop_while(&(Enum.member?(list2, &1)))
    |> Enum.count
    |> Kernel.==(0)

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

  defmodule Cache do
    use GenServer

    @service_name Application.get_env(:movies, :services)[:movie]

    def start_link do
      map = %{movie_table: :movies,
        genre_table: :genres,
        rating_table: :ratings}
      GenServer.start_link(__MODULE__, map, name: @service_name)
    end


    def init(state) do
      send(self(), :init)
      {:ok, state}
    end

    def handle_info(:init, state) do
      table_opts = [:named_table, :set, :public]
      :ets.new(state.movie_table, table_opts)
      :ets.new(state.genre_table, table_opts)
      :ets.new(state.rating_table, table_opts)

      {:noreply, state}
    end

    def handle_call({:get_movie, [id: id]}, _, %{movie_table: table} = state) do
      case :ets.lookup(table, id) do
        [] ->
          {:reply, {:error, :not_found}, state}
        [{_, movie}] ->
          {:reply, {:ok, movie}, state}
      end
    end

    def handle_call({:get_genre, [id: id]}, _, %{genre_table: table} = state) do
      case :ets.lookup(table, id) do
        [] ->
          {:reply, {:error, :not_found}, state}
        [{_, genre}] ->
          {:reply, {:ok, genre}, state}
      end
    end

    def handle_call({:get_rating, [id: id]}, _, %{rating_table: table} = state) do
      case :ets.lookup(table, id) do
        [] ->
          {:reply, {:error, :not_found}, state}
        [{_, rating}] ->
          {:reply, {:ok, rating}, state}
      end
    end

    def handle_call({:get_movie, [slug: slug]}, _, %{movie_table: table} = state) do
      result =
        :ets.tab2list(table)
        |> Enum.map(fn {_, obj} -> obj end)
        |> Enum.filter(fn %{data: %{slug: s}} -> slug == s end)

      case result do
        [] ->
          {:reply, {:error, :not_found}, state}
        [movie] ->
          {:reply, {:ok, movie}, state}
      end
    end

    def handle_call({:get_genre, [name: name]}, _, %{genre_table: table} = state) do
      name = String.downcase(name)
      result =
        :ets.tab2list(table)
        |> Enum.map(fn {_, obj} -> obj end)
        |> Enum.filter(fn %{data: %{name: n}} -> name == String.downcase(n) end)

      case result do
        [] ->
          {:reply, {:error, :not_found}, state}
        [genre] ->
          {:reply, {:ok, genre}, state}
      end
    end

    def handle_call({:get_rating, [name: name]}, _, %{rating_table: table} = state) do
      name = String.downcase(name)
      result =
        :ets.tab2list(table)
        |> Enum.map(fn {_, obj} -> obj end)
        |> Enum.filter(fn %{data: %{name: n}} -> name == String.downcase(n) end)

      case result do
        [] ->
          {:reply, {:error, :not_found}, state}
        [rating] ->
          {:reply, {:ok, rating}, state}
      end
    end

    def handle_call({:get_movies}, _, %{movie_table: table} = state) do
      movies =
        :ets.tab2list(table)
        |> Enum.map(fn {_, movie} -> movie end)

      {:reply, {:ok, movies}, state}
    end

    def handle_call({:get_genres}, _, %{genre_table: table} = state) do
      genres =
        :ets.tab2list(table)
        |> Enum.map(fn {_, genre} -> genre end)

      {:reply, {:ok, genres}, state}
    end

    def handle_call({:get_ratings}, _, %{rating_table: table} = state) do
      ratings =
        :ets.tab2list(table)
        |> Enum.map(fn {_, rating} -> rating end)

      {:reply, {:ok, ratings}, state}
    end


    def handle_cast({:seed_movies, movies}, %{movie_table: table} = state) do
      for movie <- movies, do: :ets.insert(table, {movie.id, movie})
      {:noreply, state}
    end

    def handle_cast({:seed_ratings, ratings}, %{rating_table: table} = state) do
      for rating <- ratings, do: :ets.insert(table, {rating.id, rating})
      {:noreply, state}
    end

    def handle_cast({:seed_genres, genres}, %{genre_table: table} = state) do
      for genre <- genres, do: :ets.insert(table, {genre.id, genre})
      {:noreply, state}
    end

    def handle_cast({:save_movie, %{id: id} = movie}, %{movie_table: table} = state) do
      :ets.insert(table, {id, movie})
      {:noreply, state}
    end

    def handle_cast({:save_genre, %{id: id} = genre}, %{genre_table: table} = state) do
      :ets.insert(table, {id, genre})
      {:noreply, state}
    end

    def handle_cast({:save_rating, %{id: id} = rating}, %{rating_table: table} = state) do
      :ets.insert(table, {id, rating})
      {:noreply, state}
    end

    def handle_cast({:delete_movie, [id: id]}, %{movie_table: table} = state) do
      :ets.delete(table, id)
      {:noreply, state}
    end

    def handle_cast({:delete_genre, [id: id]}, %{genre_table: table} = state) do
      :ets.delete(table, id)
      {:noreply, state}
    end

    def handle_cast({:delete_rating, [id: id]}, %{rating_table: table} = state) do
      :ets.delete(table, id)
      {:noreply, state}
    end

    def handle_cast({:delete_movies}, %{movie_table: table} = state) do
      :ets.delete_all_objects(table)
      {:noreply, state}
    end

    def handle_cast({:delete_genres}, %{genre_table: table} = state) do
      :ets.delete_all_objects(table)
      {:noreply, state}
    end

    def handle_cast({:delete_ratings}, %{rating_table: table} = state) do
      :ets.delete_all_objects(table)
      {:noreply, state}
    end
  end
end
