defmodule Moview.Movies.Rating.Schema do
  use Moview.Movies.BaseSchema, :model
  import  Moview.Movies.BaseSchema, only: [new_id: 2]

  alias Moview.Movies.Movie.Schema, as: MovieSchema

  @rating_resource 3

  schema "ratings" do
    embeds_one :data, __MODULE__.Data
    has_many :movies, MovieSchema, foreign_key: :rating_id
    timestamps()
  end

  def changeset(%{} = params) do
    %__MODULE__{}
    |> change
    |> changeset(params)
    |> new_id(@rating_resource)
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> change
    |> changeset(params)
  end

  def changeset(%Ecto.Changeset{} = struct, params) do
    case fetch_field(struct, :data) do
      {_, nil} ->
        struct
        |> put_embed(:data, __MODULE__.Data.changeset(params))
      {_, data} ->
        struct
        |> put_embed(:data, __MODULE__.Data.changeset(data, params))
    end
  end

end

defmodule Moview.Movies.Rating.Schema.Data do
  use Moview.Movies.BaseSchema, :model

  embedded_schema do
    field :name, :string
    field :delisted, :boolean, default: false
  end

  def changeset(params) do
    %__MODULE__{}
    |> changeset(params)
    |> capitalize_name
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:name, :delisted])
    |> validate_required([:name])
    |> capitalize_name
  end

  defp capitalize_name(%Ecto.Changeset{valid?: true} = changeset) do
    case changeset do
      %{changes: %{name: name}} ->
        put_change(changeset, :name, String.capitalize(name))
      _ ->
        changeset
    end
  end
  defp capitalize_name(%Ecto.Changeset{} = changeset), do: changeset
end

