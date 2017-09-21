defmodule Moview.Movies.Schedule.Server do
  use GenServer

  alias Moview.Movies.Schedule.Schema, as: Schedule
  alias Moview.Movies.Repo

  def start_link(state \\ %{schedules: []}) do
    GenServer.start_link(__MODULE__, state, name: {:global, :schedule_service})
  end

  def init(state) do
    send(self(), :init_store)
    {:ok, state}
  end

  def handle_call({:create_schedule, %Schedule{} = schedule}, _from, %{schedules: schedules} = state) do
    case Repo.insert!(schedule) do
      {:ok, schedule} ->
        {:reply, {:ok, schedule}, %{schedules: [schedule | schedules]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_schedule, %Schedule{id: id} = schedule}, _from, %{schedules: schedules} = state) do
    case Repo.update!(schedule) do
      {:ok, schedule} ->
        {:reply, {:ok, schedule}, %{schedules: [schedule | Enum.filter(schedules, &(&1.id != id))]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:get_schedule, [id: id]}, _from, %{schedules: schedules} = state) do
    case Enum.find(schedules, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      schedule ->
        {:reply, {:ok, schedule}, state}
    end
  end

  def handle_call({:get_schedules}, _from, %{schedules: schedules} = state) do
    {:reply, {:ok, schedules}, state}
  end

  def handle_call({:get_schedules, [movie_id: id]}, _from, %{schedules: schedules} = state) do
    {:reply, {:ok, Enum.filter(schedules, &(&1.movie_id == id))}, state}
  end

  def handle_call({:get_schedules, [cinema_id: id]}, _from, %{schedules: schedules} = state) do
    {:reply, {:ok, Enum.filter(schedules, &(&1.cinema_id == id))}, state}
  end

  def handle_call({:delete_schedule, [id: id]}, _from, %{schedules: schedules} = state) do
    case Enum.find(schedules, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      schedule ->
        Repo.delete!(schedule)
        {:reply, {:ok, schedule}, %{schedules: Enum.filter(schedules, &(&1.id != id))}}
    end
  end

  def handle_info(:init_store, %{schedules: _} = state) do
    schedules = Repo.all(Schedule)
    {:noreply, %{schedules: schedules}}
  end

end


