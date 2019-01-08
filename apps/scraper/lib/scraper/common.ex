defmodule Moview.Scraper.Common do
  require Logger
  alias Moview.Movies.{Cinema, Movie}
  alias Moview.Scraper.Utils

  @weekdays  ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  def generic_scrape_fun(name, module) do
    Logger.info "Begin scraping #{name}"
    {:ok, cinemas} = Cinema.get_cinemas_by_name(name)

    cinemas
    # Ignore cinemas without urls
    |> Enum.filter(fn
      %{data: %{url: ""}} -> false
      nil -> false
      _ -> true
    end)
    |> module.do_scrape
  end

  def create_or_return_movie(%{title: title} = map) do
    Logger.debug "Attempt to create movie: #{title}..."
    {:ok, movies} = Movie.get_movies()

    case Utils.get_movie_details(title) do
      {:error, _} = res ->
        Logger.error """
        #{title} is probably a Nigerian movie.
        get_movie_details(#{title}) returned #{inspect res}
        """
        Map.put(map, :movie, nil)

      {:ok, %{title: details_title, poster: poster, stars: _} = details} ->
        Enum.filter(movies, fn
          %{data: %{title: ^details_title, poster: ^poster}} -> true
          _ -> false
        end)
        |> case do
          [] ->
            case Movie.create_movie(details) do
              {:ok, movie} ->
                Logger.debug "Created movie: #{details_title}"
                Map.put(map, :movie, movie)
              _ = err ->
                Logger.error "Creating movie with #{inspect details} returned #{err}"
                Map.put(map, :movie, nil)
            end

          [movie|_] ->
            Logger.debug "Movie exists: #{movie.data.title}"
            Map.put(map, :movie, movie)
        end
    end
  end

  def create_or_return_movie(err) do
    Logger.error "Could not create movies with #{inspect err}"
    %{movie: nil}
  end

  def get_schedules_for_deletion(schedules, cinema_id, movie_id) do
    Enum.filter(schedules, fn
      %{cinema_id: ^cinema_id, movie_id: ^movie_id} -> true
      _ -> false
    end)
  end

  def get_schedule_params(times, cinema_id, movie_id, type \\ "2D") do
    Enum.map(times, fn {day, list} ->
      Enum.map(list, fn time ->
        %{time: time, day: Utils.full_day(day), movie_id: movie_id, cinema_id: cinema_id, schedule_type: type}
      end)
    end)
    |> List.flatten
  end

  def clean_title(title, unwanted_list) do
    Enum.reduce(unwanted_list, title, fn to_remove, title ->
      String.replace(title, to_remove, "")
    end)
    |> String.trim
  end

  def expand_time_string("Daily: "<> time_string) do
    time_string = time_string |> String.downcase |> String.trim

    @weekdays |> Enum.map(&(expand_time_string(&1, time_string)))
  end
  def expand_time_string("Daily " <> str), do:  expand_time_string("Daily: #{String.trim(str)}")
  def expand_time_string("Mon: " <> time_string), do: {"Mon", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Tue: " <> time_string), do: {"Tue", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Wed: " <> time_string), do: {"Wed", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Thu: " <> time_string), do: {"Thu", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Fri: " <> time_string), do: {"Fri", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Sat: " <> time_string), do: {"Sat", Utils.split_and_trim(time_string, ",")}
  def expand_time_string("Sun: " <> time_string), do: {"Sun", Utils.split_and_trim(time_string, ",")}
  def expand_time_string(str) when is_binary(str) do
    [day_range, time_string] =
      str
      |> String.downcase
      |> String.replace("to", "-")
      |> Utils.split_and_trim(":", [parts: 2])

    day_range
    |> normalize_range(",")
    |> Enum.map(&expand_range/1)
    |> List.flatten
    |> Enum.map(&(expand_time_string(&1, time_string)))
  end
  def expand_time_string(day, time_string), do: expand_time_string("#{day}: #{time_string}")

  def expand_range(stop, stop, acc), do: acc ++ [stop]
  def expand_range(start, stop, []), do: expand_range(Utils.day_after(start), stop, [start])
  def expand_range(day, stop, acc), do: expand_range(Utils.day_after(day), stop, acc ++ [day])

  def expand_range("Daily  12"), do: expand_time_string("Daily: 12:00pm")
  def expand_range(str, delim \\ "-") do
    case String.contains?(str, delim) do
      false ->
        case String.contains?(str, ",") do
          false -> [str]
          true -> Utils.split_and_trim(str, ",")
        end
      true ->
        [start, stop] =
          case Utils.split_and_trim(str, delim) do
            [start, stop] -> [start, stop]
            [start] -> [start, start]
          end

        expand_range(start, stop, [])
    end
  end

  def remove_multiple_white_spaces(str) when is_binary(str) do
    str
    |> String.replace("\r\n", "")
    |> String.replace(~r/\s{2,}/, " ")
    |> String.trim
  end
  def remove_multiple_white_spaces(stuff), do: stuff

  defp normalize_range(range, delim) do
    range
    |> Utils.split_and_trim(delim)
    |> Enum.map(fn arg ->
      case String.contains?(arg, "-") do
        true ->
          arg
          |> Utils.split_and_trim("-")
          |> Enum.map(fn x ->
            x
            |> String.downcase
            |> String.capitalize
          end)
          |> Enum.join("-")

        false ->
          arg
          |> String.downcase
          |> String.capitalize
      end
    end)
  end
end
