defmodule Moview.Movies.Schedule do
  @moduledoc """
  All cinema functions return {:ok, result} when successful else {:error, reason/changeset}
  """
  alias Moview.Movies.Schedule.Impl

  def clear_state, do: Impl.clear_state()
  def seed_from_db, do: Impl.seed_from_db()

  def create_schedule(%{day: _, time: _, schedule_type: _, movie_id: _, cinema_id: _} = params) do
    Impl.create_schedule(params)
  end

  def update_schedule(id, %{} = params) do
    Impl.update_schedule(id, params)
  end

  def delete_schedule(%{} = schedule) do
    Impl.delete_schedule(schedule)
  end

  def delete_schedule(schedule_id) do
    case get_schedule(schedule_id) do
      {:ok, schedule} -> Impl.delete_schedule(schedule)
      err -> err
    end
  end

  def get_schedule(id) do
    Impl.get_schedule(id)
  end

  def get_schedules_by_cinema(id) do
    Impl.get_schedules_by_cinema(id)
  end

  def get_schedules_by_movie(id) do
    Impl.get_schedules_by_movie(id)
  end

  def get_schedules_by_day_and_movie_id(day, movie_id) do
    Impl.get_schedules_by_day_and_movie_id(day, movie_id)
  end

  def get_schedules_by_day_and_cinema_id(day, cinema_id) do
    Impl.get_schedules_by_day_and_cinema_id(day, cinema_id)
  end

  def get_schedules do
    Impl.get_schedules()
  end
end

