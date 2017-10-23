defmodule Moview.Web.Cache.Impl do
  @service_name Application.get_env(:web, :cache)

  def get_schedules(movie_id) do
    GenServer.call(@service_name, {:get_schedules, movie_id})
  end


  defmodule CacheServer do
    use GenServer
    alias Moview.Movies.{Schedule, Cinema}

    @service_name Application.get_env(:web, :cache)
    @interval 600 # 10 minutes

    @days %{1 => "Monday",
      2 => "Tuesday",
      3 => "Wednesday",
      4 => "Thursday",
      5 => "Friday",
      6 => "Saturday",
      7 => "Sunday"}

    def start_link do
      GenServer.start_link(__MODULE__, %{table: :schedule_cache}, name: @service_name)
    end

    def init(state) do
      send(self(), :init)
      {:ok, state}
    end

    def handle_info(:init, %{table: table}) do
      :ets.new(table, [:named_table, :set, :public])
      {:noreply, %{table: table}}
    end

    def handle_call({:get_schedules, movie_id}, _, %{table: table} = state) do
      schedules =
        case :ets.lookup(table, movie_id) do
          [] ->
            # We found nothing; re-compute schedules
            movie_id
            |> compute_schedules
            |> insert_schedules(movie_id, table)
          [{_, {schedules, ts}}] ->
            now_ts = :calendar.local_time |> to_ts
            # If it's less than @interval since last computation, return last computation
            case now_ts - ts <= @interval do
              true -> schedules
              false ->
                # Our cache interval has elapsed. Re-compute
                movie_id
                |> compute_schedules
                |> insert_schedules(movie_id, table)
            end
        end
      {:reply, {:ok, schedules}, state}
    end

    defp insert_schedules(schedules, movie_id, table) do
      now_ts = :calendar.local_time |> to_ts
      :ets.insert(table, {movie_id, {schedules, now_ts}})
      schedules
    end

    defp compute_schedules(movie_id) do
      {:ok, schedules} = Schedule.get_schedules_by_movie(movie_id)
      {:ok, cinemas} = Cinema.get_cinemas()

      now = :calendar.local_time()
      date_list = date_list(now, next_thursday())
      now_ts = :calendar.local_time |> to_ts

      schedules
      |> Enum.map(fn sched ->
        cinema =
          case Enum.find(cinemas, "", fn c -> c.id == sched.cinema_id end) do
            "" -> ""
            %{data: %{name: name, branch_title: branch, city: city}} ->
              case branch do
                "" -> "#{name}, #{city}"
                _ -> "#{name} (#{branch}), #{city}"
              end
          end

        sched
        |> Map.get(:data)
        |> Map.delete(:__struct__)
        |> Map.put(:id, sched.id)
        |> Map.put(:cinema_id, sched.cinema_id)
        |> Map.put(:cinema, cinema)
      end)
      |> Enum.filter(fn %{day: day} ->
        Enum.find(date_list, fn
          {^day, _} -> true
          _ -> false
        end) != nil
      end)
      |> Enum.map(&(Map.put(&1, :ts, sched_ts(&1, date_list))))
      |> Enum.filter(&(&1.ts > now_ts)) # Remove past schedules
      |> Enum.sort(&(&1.ts <= &2.ts)) # Sort by earliest
    end

    defp sched_ts(%{day: day, time: time}, date_list) do
      {_, {date, _}} =
        Enum.find(date_list, fn
          {^day, _} -> true
          _ -> false
        end)
      to_ts({date, time_string_to_tuple(time)})
    end

    defp time_string_to_tuple(time) when is_binary(time) do
      time =
        time
        |> String.downcase
        |> String.replace(".", ":") # Some crazy cinemas use . instead of : for time

      time =
        case String.contains?(time, ":") do
          true -> time
          false -> "#{time}:00"
        end

      case String.contains?(time, "am") do
        true ->
          time = String.replace(time, "am", "")
          time_string_to_tuple(time, [add: 0])
        false ->
          time = String.replace(time, "pm", "")
          time_string_to_tuple(time, [add: 12])
      end
    end
    defp time_string_to_tuple(time, [add: hrs]) do
      [hours, minutes] =
        time
        |> String.split(":")
        |> Enum.map(&(&1 |> String.replace(~r/\D/, "") |> String.to_integer))

      case hours == 12 do
        false -> # Add 12 hours to convert to 24-hour format
          {hours + hrs, minutes, 0}
        true ->
          case hrs do
            0 -> # 12am
              {0, minutes, 0}
            12 -> # 12pm, don't add
              {hours, minutes, 0}
          end
      end
    end

    defp next_thursday do
      next_thursday(:calendar.local_time())
    end
    defp next_thursday({date, _} = erl_time) do
      case "Thursday" == day_from_date(date) do
        true -> erl_time
        false ->
          erl_time
          |> next_day
          |> next_thursday
      end
    end

    defp date_list(start, stop), do: date_list(start, stop, [])
    defp date_list(erl_time, erl_time, list) do
      list ++ [{day_from_date(erl_time), erl_time}]
    end
    defp date_list(start_erl_time, end_erl_time, list) do
      list = list ++ [{day_from_date(start_erl_time), start_erl_time}]
      date_list(next_day(start_erl_time), end_erl_time, list)
    end

    defp next_day(erl_time) do
      erl_time
      |> NaiveDateTime.from_erl
      |> elem(1)
      |> NaiveDateTime.add(86400, :second)
      |> NaiveDateTime.to_erl
    end

    defp day_from_date({y, m, d}) do
      Map.get(@days, :calendar.day_of_the_week(y, m, d))
    end

    defp day_from_date({{_, _, _} = date, _}), do: day_from_date(date)

    defp to_ts({{_,_,_},{_,_,_}}=datetime_tup), do:  :calendar.datetime_to_gregorian_seconds(datetime_tup) - 62167219200

  end
end
