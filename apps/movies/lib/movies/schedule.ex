defmodule Moview.Movies.Schedule do
  alias Moview.Movies.Schedule.Schema, as: Schedule

  @service_name {:global, :schedule_service}

  def get_schedules_by_cinema(id) do
    GenServer.call(@service_name, {:get_schedule, [cinema_id: id]})
  end

  def create_schedule(%{} = params) do
    :ok
  end

  def update_schedule(id, %{} = params) do
    :ok
  end

  def delete_schedule(id) do
    GenServer.call(@service_name, {:delete_schedule, [id: id]})
  end

  def get_schedule(id) do
    GenServer.call(@service_name, {:get_schedule, [id: id]})
  end

  def get_schedules_by_movie_id(id) do
    GenServer.call(@service_name, {:get_schedule, [movie_id: id]})
  end

  def get_schedules do
    GenServer.call(@service_name, {:get_schedules})
  end
end

