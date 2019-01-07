defmodule Moview.Movies.Cinema.Schema do
  use Moview.Movies.BaseSchema, :model
  import  Moview.Movies.BaseSchema, only: [new_id: 2]

  alias Moview.Movies.Schedule.Schema, as: ScheduleSchema

  @cinema_resource 4

  schema "cinemas" do
    embeds_one :data, __MODULE__.Data
    has_many :schedules, ScheduleSchema, foreign_key: :cinema_id
    timestamps()
  end

  def changeset(%{} = params) do
    %__MODULE__{}
    |> change
    |> changeset(params)
    |> new_id(@cinema_resource)
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> change
    |> changeset(params)
  end

  def changeset(%Ecto.Changeset{} = struct, params) do
    struct =
      case fetch_field(struct, :data) do
        {_, nil} ->
          struct
          |> put_embed(:data, __MODULE__.Data.changeset(params))
        {_, data} ->
          struct
          |> put_embed(:data, __MODULE__.Data.changeset(data, params))
      end

    case Map.get(params, :id) do
      nil -> struct
      id -> put_change(struct, :id, id)
    end
  end

end

defmodule Moview.Movies.Cinema.Schema.Data do
  use Moview.Movies.BaseSchema, :model

  embedded_schema do
    field :name, :string, default: ""
    field :city, :string, default: ""
    field :address, :string, default: ""
    field :branch_title, :string, default: ""
    field :url, :string, default: ""
    field :delisted, :boolean, default: false
  end

  def changeset(params) do
    %__MODULE__{}
    |> changeset(params)
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:name, :city, :address, :branch_title, :url, :delisted])
    |> validate_required([:name, :city, :address])
  end

end

