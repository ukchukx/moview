defmodule Moview.Movies.Movie.Schema do
  use Moview.Movies.BaseSchema, :model
  import  Moview.Movies.BaseSchema, only: [new_id: 2]

  alias Moview.Movies.Rating.Schema, as: RatingSchema
  alias Moview.Movies.Schedule.Schema, as: ScheduleSchema
  alias Moview.Movies.Genre.Schema, as: GenreSchema
  alias Moview.Movies.{Movie, Repo}

  @movie_resource 1
  @slug_fun &Movie.slug_generator/2

  schema "movies" do
    embeds_one :data, __MODULE__.Data
    belongs_to :rating, RatingSchema
    has_many :schedules, ScheduleSchema, foreign_key: :movie_id
    many_to_many :genres, GenreSchema, join_through: "movies_genres", join_keys: [movie_id: :id, genre_id: :id]
    timestamps()
  end

  def changeset(%{} = params) do
    %__MODULE__{}
    |> change
    |> changeset(params)
    |> new_id(@movie_resource)
    |> generate_slug
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> change
    |> changeset(params)
    |> generate_slug
  end

  def changeset(%Ecto.Changeset{} = struct, params) do
    case fetch_field(struct, :data) do
      {_, nil} ->
        struct
        |> cast(params, [:rating_id])
        |> put_embed(:data, __MODULE__.Data.changeset(params))
      {_, data} ->
        struct
        |> cast(params, [:rating_id])
        |> put_embed(:data, __MODULE__.Data.changeset(data, params))
    end
  end

  def associate_genres(%__MODULE__{} = movie, %GenreSchema{} = genre) do
    associate_genres(movie, [genre])
  end

  def associate_genres(%__MODULE__{} = movie, genres) when is_list(genres) do
    movie
    |> Repo.preload(:genres)
    |> change
    |> put_assoc(:genres, genres)
    |> Repo.update!
  end

  defp generate_slug(%Ecto.Changeset{valid?: true} = changeset), do: generate_slug(changeset, @slug_fun)
  defp generate_slug(%Ecto.Changeset{valid?: false} = changeset, _), do: changeset
  defp generate_slug(%Ecto.Changeset{valid?: true} = changeset, slug_fun) do
    case changeset do
      %{changes: %{data: %{changes: %{title: title}}}} ->
        id = get_field(changeset, :id)
        data = get_field(changeset, :data)

        changeset
        |> put_embed(:data, __MODULE__.Data.changeset(data, %{slug: slug_fun.(title, id)}))
      _ ->
        changeset
    end
  end

end

defmodule Moview.Movies.Movie.Schema.Data do
  use Moview.Movies.BaseSchema, :model

  embedded_schema do
    field :title, :string, default: ""
    field :slug, :string, default: ""
    field :trailer, :string, default: ""
    field :synopsis, :string, default: ""
    field :runtime, :integer, default: 0
    field :stars, {:array, :string}
    field :poster, :string, default: ""
    field :delisted, :boolean, default: false
  end

  def changeset(params) do
    %__MODULE__{}
    |> changeset(params)
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:title, :slug, :trailer, :synopsis, :runtime, :stars, :poster, :delisted])
    |> validate_required([:title, :runtime, :stars])
  end

end

