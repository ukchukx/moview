defmodule Moview.Movies.Movie do
  @moduledoc """
  All movie, rating and genre functions return {:ok, result} when successful else {:error, reason/changeset}
  """

  alias Moview.Movies.Movie.Schema, as: Movie
  alias Moview.Movies.Genre.Schema, as: Genre
  alias Moview.Movies.Rating.Schema, as: Rating

  @service_name {:global, Application.get_env(:movies, :services)[:movie] }

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


  def get_state, do: GenServer.call(@service_name, :which_state)

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

    changeset = Movie.changeset(params)
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        case GenServer.call(@service_name, {:create_movie, changeset}) do
          {:ok, movie} ->
            # Associate genres
            genres = Enum.map(genres, &String.downcase/1)
            movie_genres = Enum.filter(genre_list, fn genre -> String.downcase(genre.data.name) in genres end)
            {:ok, Movie.associate_genres(movie, movie_genres)}
          {:error, changeset} ->
            {:error, changeset}
        end
      %Ecto.Changeset{valid?: false} ->
        {:error, changeset}
    end
  end

  def create_genre(%{name: name} = params) do
    case get_genre_by_name(name) do
      {:ok, genre} ->
        {:ok, genre}
      {:error, :not_found} ->
        changeset = Genre.changeset(params)
        case changeset do
          %Ecto.Changeset{valid?: true} ->
            GenServer.call(@service_name, {:create_genre, changeset})
          %Ecto.Changeset{valid?: false} ->
            {:error, changeset}
        end
    end
  end

  def create_rating(%{name: name} = params) do
    case get_rating_by_name(name) do
      {:ok, rating} ->
        {:ok, rating}
      {:error, :not_found} ->
        changeset = Rating.changeset(params)
        case changeset do
          %Ecto.Changeset{valid?: true} ->
            GenServer.call(@service_name, {:create_rating, changeset})
          %Ecto.Changeset{valid?: false} ->
            {:error, changeset}
        end
    end
  end

  def update_movie(id, params) do
    case get_movie(id) do
      {:ok, movie} ->
        changeset = Movie.changeset(movie, params)
        case changeset do
          %Ecto.Changeset{valid?: true} ->
            GenServer.call(@service_name, {:update_movie, changeset})
          %Ecto.Changeset{valid?: false} ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def update_genre(id, params) do
    case get_genre(id) do
      {:ok, genre} ->
        changeset = Genre.changeset(genre, params)
        case changeset do
          %Ecto.Changeset{valid?: true} ->
            GenServer.call(@service_name, {:update_genre, changeset})
          %Ecto.Changeset{valid?: false} ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def update_rating(id, %{name: new_name} = params) do
    case get_rating(id) do
      {:ok, rating} ->
        changeset = Rating.changeset(rating, params)
        case changeset do
          %Ecto.Changeset{valid?: true} ->
            case get_rating_by_name(new_name) do
              {:ok, _} ->
                {:error, :name_exists}
              {:error, :not_found} ->
                GenServer.call(@service_name, {:update_rating, changeset})
            end
          %Ecto.Changeset{valid?: false} ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end


  def delete_movie(id) do
    GenServer.call(@service_name, {:delete_movie, [id: id]})
  end

  def delete_genre(id) do
    GenServer.call(@service_name, {:delete_genre, [id: id]})
  end

  def delete_rating(id) do
    GenServer.call(@service_name, {:delete_rating, [id: id]})
  end


  def delete_movies do
    GenServer.cast(@service_name, {:delete_movies})
  end

  def delete_genres do
    GenServer.cast(@service_name, {:delete_genres})
  end

  def delete_ratings do
    GenServer.cast(@service_name, {:delete_ratings})
  end


  def get_movie(id) do
    GenServer.call(@service_name, {:get_movie, [id: id]})
  end

  def get_movie_by_slug(slug) do
    GenServer.call(@service_name, {:get_movie, [slug: slug]})
  end

  def get_movies do
    GenServer.call(@service_name, {:get_movies})
  end


  def get_genre(id) do
    GenServer.call(@service_name, {:get_genre, [id: id]})
  end

  def get_genre_by_name(name) do
    GenServer.call(@service_name, {:get_genre, [name: name]})
  end

  def get_genres do
    GenServer.call(@service_name, {:get_genres})
  end


  def get_rating(id) do
    GenServer.call(@service_name, {:get_rating, [id: id]})
  end

  def get_rating_by_name(name) do
    GenServer.call(@service_name, {:get_rating, [name: name]})
  end

  def get_ratings do
    GenServer.call(@service_name, {:get_ratings})
  end


  def clear_state do
    delete_movies()
    delete_ratings()
    delete_genres()
  end

end
