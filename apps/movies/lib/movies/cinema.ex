defmodule Moview.Movies.Cinema do
  alias Moview.Movies.Cinema.Schema, as: Cinema

  @service_name {:global, :cinema_service}


  def get_cinemas_by_name(name) do
    GenServer.call(@service_name, {:get_cinemas, [name: name]})
  end

  def create_cinema(%{} = params) do
    :ok
  end

  def update_cinema(id, %{} = params) do
    :ok
  end

  def delete_cinema(id) do
    GenServer.call(@service_name, {:delete_cinema, [id: id]})
  end

  def get_cinema(id) do
    GenServer.call(@service_name, {:get_cinema, [id: id]})
  end

  def get_cinemas do
    GenServer.call(@service_name, {:get_cinemas})
  end
end

