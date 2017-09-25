defmodule Moview.Movies.BaseSchema do
  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def new_id(%Ecto.Changeset{valid?: true} = changeset, resource_type) do
    Ecto.Changeset.put_change(changeset, :id, Ruid.generate(resource_type))
  end
  def new_id(%Ecto.Changeset{} = changeset), do: changeset

  def to_map(list) when is_list(list) do
    list
    |> Enum.reduce(%{}, fn resource = %{id: id}, acc -> Map.put(acc, id, resource) end)
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
