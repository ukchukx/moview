defmodule Moview.Auth.User.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  import Moview.Auth.User, only: [new_id: 2]

  @user_resource 6

  schema "users" do
    embeds_one :data, __MODULE__.Data
    timestamps()
  end

  def changeset(params) do
    %__MODULE__{}
    |> change()
    |> put_embed(:data, __MODULE__.Data.changeset(params))
    |> new_id(@user_resource)
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

defmodule Moview.Auth.User.Schema.Data do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :email, :string, default: ""
    field :password_hash, :string, default: ""
    field :password, :string, virtual: true
    field :role, :string, default: "user"
    field :delisted, :boolean, default: false
  end

  def changeset(params) do
    %__MODULE__{}
    |> changeset(params)
    |> cast(params, [:email, :role, :password_hash, :delisted])
    |> validate_required([:email, :role])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:role, ["user", "admin"])
  end

  def change_password(struct, %{password: _} = _) do
    struct
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash
  end
  def change_password(struct, _), do: struct

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:email, :password, :role, :password_hash, :delisted])
    |> change_password(params)
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end
end
