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


  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
