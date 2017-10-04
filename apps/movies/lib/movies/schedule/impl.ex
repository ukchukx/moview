defmodule Moview.Movies.Schedule.Impl do
  import Moview.Movies.BaseSchema, only: [to_map: 1]
  import Ecto.Query

  alias Moview.Movies.Schedule.Schema, as: Schedule
  alias Moview.Movies.Repo

  @service_name Application.get_env(:movies, :services)[:schedule]

  def clear_state do
    delete_schedules()
  end

  def create_schedule(%{cinema_id: cid, movie_id: mid, day: day, time: time, schedule_type: stype} = params) do
    import Moview.Movies.Cinema, only: [get_cinema: 1]
    import Moview.Movies.Movie, only: [get_movie: 1]

    err =
      case get_cinema(cid) do
        {:error, _} -> %{cinema_id: :not_found}
        {:ok, _} -> %{}
      end

    err =
      case get_movie(mid) do
        {:error, _} -> Map.put(err, :movie_id, :not_found)
        {:ok, _} -> err
      end

    case err do
      %{movie_id: :not_found, cinema_id: :not_found} = err -> {:error, err}
      %{cinema_id: :not_found} = err -> {:error, err}
      %{movie_id: :not_found} = err -> {:error, err}
      %{} ->
        duplicate_schedules =
          cid
          |> get_schedules_by_cinema
          |> elem(1)
          |> Enum.filter(fn
            %{movie_id: ^mid, cinema_id: ^cid, data: %{day: ^day, schedule_type: ^stype, time: ^time}} -> true
            _ -> false
          end)

        case duplicate_schedules do
          [] ->
            case Schedule.changeset(params) do
              %Ecto.Changeset{valid?: true} = changeset ->
                case Repo.insert!(changeset) do
                  {:error, _changeset} = err -> err
                  schedule ->
                    GenServer.cast(@service_name, {:save_schedule, schedule})
                    {:ok, schedule}
                end
              %Ecto.Changeset{valid?: false} = changeset ->
                {:error, changeset}
            end
          [duplicate] ->
            {:ok, duplicate}
        end
    end
  end

  def update_schedule(id, %{} = params) do
    case get_schedule(id) do
      {:ok, schedule} ->
        case Schedule.changeset(schedule, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.update!(changeset) do
              {:error, changeset} ->
                {:error, changeset}
              schedule ->
                GenServer.cast(@service_name, {:save_schedule, schedule})
                {:ok, schedule}
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get_schedules do
    case GenServer.call(@service_name, {:get_schedules}) do
      {:ok, []} ->
        case Repo.all(Schedule) do
          [] ->
            {:ok, []}
          schedules ->
            Enum.each(schedules, fn schedule -> GenServer.cast(@service_name, {:save_schedule, schedule}) end)
            {:ok, schedules}
        end
      {:ok, _schedules} = res -> res
    end
  end

  def get_schedule(id) do
    case GenServer.call(@service_name, {:get_schedule, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(Schedule, id) do
          nil -> err
          schedule ->
            GenServer.cast(@service_name, {:save_schedule, schedule})
            {:ok, schedule}
        end
      {:ok, schedule} ->
        {:ok, schedule}
    end
  end

  def get_schedules_by_movie(movie_id) do
    case GenServer.call(@service_name, {:get_schedules, [movie_id: movie_id]}) do
      {:ok, []} = empty_result ->
        case Repo.all(from r in Schedule, where: r.movie_id == ^movie_id) do
          [] -> empty_result
          schedules ->
            Enum.each(schedules, fn schedule -> GenServer.cast(@service_name, {:save_schedule, schedule}) end)
            {:ok, schedules}
        end
      {:ok, schedules} ->
        {:ok, schedules}
    end
  end

  def get_schedules_by_cinema(cinema_id) do
    case GenServer.call(@service_name, {:get_schedules, [cinema_id: cinema_id]}) do
      {:ok, []} = empty_result ->
        case Repo.all(from r in Schedule, where: r.cinema_id == ^cinema_id) do
          [] -> empty_result
          schedules ->
            Enum.each(schedules, fn schedule -> GenServer.cast(@service_name, {:save_schedule, schedule}) end)
            {:ok, schedules}
        end
      {:ok, schedules} ->
        {:ok, schedules}
    end
  end

  def get_schedules_by_day_and_cinema_id(day, cinema_id) do
    case GenServer.call(@service_name, {:get_schedules, [day: day, cinema_id: cinema_id]}) do
      {:ok, []} = empty_result ->
        lday = String.downcase(day)
        result = Repo.all(from r in Schedule,
                        where: fragment("lower(data->>'day') = ? AND cinema_id = ?", ^lday, ^cinema_id))
        case result do
          [] -> empty_result
          schedules ->
            Enum.each(schedules, fn schedule -> GenServer.cast(@service_name, {:save_schedule, schedule}) end)
            {:ok, schedules}
        end
      {:ok, schedules} ->
        {:ok, schedules}
    end
  end

  def get_schedules_by_day_and_movie_id(day, movie_id) do
    case GenServer.call(@service_name, {:get_schedules, [day: day, movie_id: movie_id]}) do
      {:ok, []} = empty_result ->
        lday = String.downcase(day)
        result = Repo.all(from r in Schedule,
                        where: fragment("lower(data->>'day') = ? AND movie_id = ?", ^lday, ^movie_id))
        case result do
          [] -> empty_result
          schedules ->
            Enum.each(schedules, fn schedule -> GenServer.cast(@service_name, {:save_schedule, schedule}) end)
            {:ok, schedules}
        end
      {:ok, schedules} ->
        {:ok, schedules}
    end
  end

  def delete_schedule(%Schedule{id: id} = schedule) do
    GenServer.cast(@service_name, {:delete_schedule, [id: id]})
    {:ok, Repo.delete!(schedule)}
  end

  def delete_schedules do
    GenServer.cast(@service_name, {:delete_schedules})
    Repo.delete_all(Schedule)
  end


  defmodule Cache do
    use GenServer

    @service_name Application.get_env(:movies, :services)[:schedule]

    def start_link do
      scheds = Repo.all(Schedule) |> to_map
      GenServer.start_link(__MODULE__, %{schedules: scheds, table: :schedules}, name: @service_name)
    end

    def init(%{schedules: scheds, table: table}) do
      :ets.new(table, [:named_table, :set, :public])
      for sched <- scheds, do: :ets.insert(table, {sched.id, sched})
      {:ok, %{table: table}}
    end

    def handle_call({:get_schedule, [id: id]}, _, %{table: table} = state) do
      case :ets.lookup(table, id) do
        [] ->
          {:reply, {:error, :not_found}, state}
        [{_, schedule}] ->
          {:reply, {:ok, schedule}, state}
      end
    end

    def handle_call({:get_schedules, [cinema_id: cid]}, _, %{table: table} = state) do
      schedules =
        :ets.tab2list(table)
        |> Enum.map(fn {_, s} -> s end)
        |> Enum.filter(&(&1.cinema_id == cid))

      {:reply, {:ok, schedules}, state}
    end

    def handle_call({:get_schedules, [movie_id: mid]}, _, %{table: table} = state) do
      schedules =
        :ets.tab2list(table)
        |> Enum.map(fn {_, s} -> s end)
        |> Enum.filter(&(&1.movie_id == mid))

      {:reply, {:ok, schedules}, state}
    end

    def handle_call({:get_schedules, [day: day, cinema_id: cid]}, _, %{table: table} = state) do
      schedules =
        :ets.tab2list(table)
        |> Enum.map(fn {_, s} -> s end)
        |> Enum.filter(&(&1.cinema_id == cid and &1.data.day == day))
      {:reply, {:ok, schedules}, state}
    end

    def handle_call({:get_schedules, [day: day, movie_id: mid]}, _, %{table: table} = state) do
      schedules =
        :ets.tab2list(table)
        |> Enum.map(fn {_, s} -> s end)
        |> Enum.filter(&(&1.movie_id == mid and &1.data.day == day))

      {:reply, {:ok, schedules}, state}
    end

    def handle_call({:get_schedules}, _, %{table: table} = state) do
      schedules =
        :ets.tab2list(table)
        |> Enum.map(fn {_, s} -> s end)

      {:reply, {:ok, schedules}, state}
    end

    def handle_cast({:save_schedule, %{id: id} = schedule}, %{table: table} = state) do
      :ets.insert(table, {id, schedule})
      {:noreply, state}
    end

    def handle_cast({:delete_schedule, [id: id]}, %{table: table} = state) do
      :ets.delete(table, id)
      {:noreply, state}
    end

    def handle_cast({:delete_schedules}, %{table: table} = state) do
      :ets.delete_all_objects(table)
      {:noreply, state}
    end

  end
end

