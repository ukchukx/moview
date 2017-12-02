defmodule Moview.Scraper.Genesis.Impl do
  require Logger
  alias Moview.Movies.{Movie, Schedule}
  alias Moview.Scraper.Utils

  @weekdays  ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  def do_scrape(cinemas) do
    cinemas
    # Ignore cinemas without urls
    |> Enum.filter(fn
      %{data: %{url: ""}} -> false
      nil -> false
      _ -> true
    end)
    |> Enum.map(fn %{data: %{url: url, address: a, branch_title: b}, id: cinema_id} ->
      Logger.info "Beginning to scrape: (#{b}) @ #{a}"
      scrape(url)
      |> Enum.map(&create_or_return_movie/1)
      |> Enum.filter(fn
        %{movie: nil} -> false
        _ -> true
      end)
      |> Enum.map(fn %{movie: %{id: movie_id, data: %{title: title}}, times: times} ->
        Logger.info("Fetching schedules to clear for movie #{title}")
        {:ok, schedules} = Schedule.get_schedules()
        deletion_candidates = get_schedules_for_deletion(schedules, cinema_id, movie_id)

        Logger.info("Creating schedules params for movie #{title}")
        schedule_params = get_schedule_params(times, cinema_id, movie_id)

        %{delete: deletion_candidates, create: schedule_params}
      end)
    end)
    |> List.flatten
  end

  defp get_schedules_for_deletion(schedules, cinema_id, movie_id) do
    Enum.filter(schedules, fn
      %{cinema_id: ^cinema_id, movie_id: ^movie_id} -> true
      _ -> false
    end)
  end

  defp get_schedule_params(times, cinema_id, movie_id) do
    Enum.map(times, fn {day, list} ->
      Enum.map(list, fn time ->
        %{time: time, day: Utils.full_day(day), movie_id: movie_id, cinema_id: cinema_id, schedule_type: "2D"}
      end)
    end)
    |> List.flatten
  end

  defp create_or_return_movie(%{title: title} = map) do
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
        |> case  do
          [] ->
            case Movie.create_movie(details) do
              {:ok, movie} ->
                Logger.info "Created movie: #{details_title}"
                Map.put(map, :movie, movie)
              _ = err ->
                Logger.error "Creating movie with #{inspect details} returned #{err}"
                Map.put(map, :movie, nil)
            end
          [movie|_] ->
            Logger.info "Movie exists: #{movie.data.title}"
            Map.put(map, :movie, movie)
        end
    end
  end
  defp create_or_return_movie(err) do
    Logger.error "Could not create movies with #{inspect err}"
    %{movie: nil}
  end

  defp scrape(url) do
    url
    |> Utils.make_request(false)
    |> Floki.find("section.container > div.col-sm-8.col-md-9 > div.movie.release")
    |> Enum.map(&movie_node/1) # Get as nodes
    |> Enum.map(&extract_info_from_node/1)
  end

  defp extract_info_from_node(movie_node) do
    title = movie_title(movie_node)
    times =
      movie_node
      |> movie_time_strings
      |> Enum.map(&expand_time_string/1)
      |> List.flatten

    %{title: title, times: times}
  end

  defp movie_node({_, _, nodes}), do:  Enum.at(nodes, 1)

  defp movie_title({_, _, [a_node |_]}) do
    {"a", _, [title]} = a_node
    title
    |> clean_title
    |> String.trim
    |> String.downcase
    |> String.capitalize
  end

  defp movie_time_strings({_, _, [_|nodes]}) do
    days = ["Daily" | @weekdays]
    nodes
    |> Enum.filter(fn
      {"p", attrs, _} -> Enum.member?(attrs, {"class", "movie__option"})
      _ -> false
    end)
    |> Enum.filter(fn {_, _, nodes} ->
      nodes
      |> Enum.any?(fn
        {"strong", _, [day_range]} -> Enum.any?(days, &(String.contains?(day_range, &1)))
        _ -> false
      end)
    end)
    |> Enum.map(fn {_, _, [{"strong", _, [day_range]}, time_string]} ->
      String.trim(day_range) <> " " <> time_string
    end)
  end

  defp clean_title(title), do: title |> String.replace("(NEW)", "")

  defp expand_time_string("Daily: "<> time_string) do
    @weekdays |> Enum.map(&(expand_time_string(&1, String.trim(time_string))))
  end
  defp expand_time_string("Mon: " <> time_string), do: {"Mon", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Tue: " <> time_string), do: {"Tue", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Wed: " <> time_string), do: {"Wed", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Thu: " <> time_string), do: {"Thu", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Fri: " <> time_string), do: {"Fri", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Sat: " <> time_string), do: {"Sat", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Sun: " <> time_string), do: {"Sun", Utils.split_and_trim(time_string, " ")}
  defp expand_time_string("Daily " <> str), do:  expand_time_string("Daily: #{String.trim(str)}")
  defp expand_time_string(str) when is_binary(str) do
    [day_range, time_string] = Utils.split_and_trim(str, ":", [parts: 2])
    [day_range, time_string] =
      case day_range do
        "Daily  12" -> ["Daily", "12:00pm " <> time_string]
        _ -> [day_range, time_string]
      end

    Utils.split_and_trim(day_range, "&")
    |> Enum.map(&expand_range/1)
    |> List.flatten
    |> Enum.map(&(expand_time_string(&1, time_string)))
  end
  defp expand_time_string(day, time_string), do: expand_time_string("#{day}: #{time_string}")

  defp expand_range("Daily  12"), do: expand_time_string("Daily: 12:00pm")
  defp expand_range(str) do
    case String.contains?(str, "-") do
      false ->
        case String.contains?(str, ",") do
          false -> [str]
          true -> Utils.split_and_trim(str, ",")
        end
      true ->
        [start, stop] = Utils.split_and_trim(str, "-")
        expand_range(start, stop, [])
    end
  end
  defp expand_range(stop, stop, acc), do: acc ++ [stop]
  defp expand_range(start, stop, []), do: expand_range(Utils.day_after(start), stop, [start])
  defp expand_range(day, stop, acc), do: expand_range(Utils.day_after(day), stop, acc ++ [day])
end

