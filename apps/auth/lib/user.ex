defmodule Moview.Auth.User do
  alias Moview.Auth.User.Impl

  def new_id(%Ecto.Changeset{valid?: true} = changeset, resource_type) do
    Ecto.Changeset.put_change(changeset, :id, Ruid.generate(resource_type))
  end
  def new_id(%Ecto.Changeset{valid?: false} = changeset, _), do: changeset

  def to_map(list) when is_list(list) do
    list
    |> Enum.reduce(%{}, fn %{id: id} = resource,  acc -> Map.put(acc, id, resource) end)
  end

  def seed_from_db, do: Impl.seed_from_db()

  def create_user(params) do
    Impl.create_user(params)
  end

  def update_user(id, params) do
    Impl.update_user(id, params)
  end

  def get_user(id) do
    Impl.get_user(id)
  end

  def get_user_by_email(email) do
    Impl.get_user_by_email(email)
  end

  def get_users do
    Impl.get_users()
  end

  def delete_user(user) do
    Impl.delete_user(user)
  end

  def delete_users do
    Impl.delete_users()
  end

  def clear_state, do: Impl.clear_state()
end
