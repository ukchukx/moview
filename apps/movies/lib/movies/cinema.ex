defmodule Moview.Movies.Cinema do
  @moduledoc """
  All cinema functions return {:ok, result} when successful else {:error, reason/changeset}
  """
  alias Moview.Movies.Cinema.Impl

  @service_name Application.get_env(:movies, :services)[:cinema]


  def create_cinema(%{name: _, address: _, city: _} = params) do
    Impl.create_cinema(params)
  end

  def update_cinema(id, %{} = params) do
    Impl.update_cinema(id, params)
  end

  def delete_cinema(id) do
    Impl.delete_cinema(id)
  end

  def get_cinema(id) do
    Impl.get_cinema(id)
  end

  def get_cinemas_by_name(name) do
    Impl.get_cinemas_by_name(name)
  end

  def get_cinemas do
    Impl.get_cinemas()
  end
end

