defmodule Moview.Scraper.Filmhouse.Impl do
  require Logger
  alias Moview.Movies.{Movie, Cinema, Schedule}
  alias Moview.Scraper.Utils

  def scrape do
    Logger.info "Begin scraping Filmhouse Cinemas"
    {:ok, cinemas} = Cinema.get_cinemas_by_name("Filmhouse Cinemas")

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

  defp scrape(url) do
    url
    |> Utils.make_request(false)
    |> Floki.find("div.col-lg-7.col-md-6 > div.section_5")
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

  defp movie_title({_, _, [div_node | _]}) do
    {"div", [{"class", "clearfix"}], [title_node | _]} = div_node
    {"b", _, [{_, _, [title | _]}]} = title_node

    title
    |> String.trim
    |> String.downcase
    |> String.capitalize
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
          [movie] ->
            Logger.info "Movie exists: #{movie.data.title}"
            Map.put(map, :movie, movie)
        end
    end
  end
  defp create_or_return_movie(err) do
    Logger.error "Could not create movies with #{inspect err}"
    %{movie: nil}
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

  defp movie_time_strings({_, _, [_ | nodes]}) do
    [{"div", [{"class", "post_text"}], [_ | nodes]}] = nodes
    [{"div", _, [_ | nodes]}] = nodes
    time_info =
      nodes
      |> Enum.reduce([], fn n, acc ->
        case is_list(n) do
          false ->
            case n do
              {"p", _, [first_node | rest]} ->
                other_nodes =
                  case first_node do
                    {"strong", [], [str]} when is_binary(str) -> [first_node]
                    {"strong", [], [_ | other_nodes]} ->
                      Enum.map(other_nodes, fn
                        item when is_binary(item) -> String.trim(item)
                        item -> item
                      end)
                    _ -> [first_node]
                  end

                nodes =  other_nodes ++ rest |> Enum.filter(fn
                  {"br", [], []} -> false
                  str when is_binary(str) -> str |> String.trim |> String.length |> Kernel.>(0)
                  _ -> true
                end)

                acc ++ nodes
               _ -> acc ++ [n]
            end
          true ->
            Enum.map(n, fn
              {"p", _, nodes} -> nodes
              stuff -> stuff
            end) ++ acc
        end
      end)
      |> Enum.filter(fn
        {"strong", [], [child_node]} when is_binary(child_node) -> true
        str when is_binary(str) -> true
        _ -> false
      end)

    case rem(Enum.count(time_info), 2) do
      0 -> time_info
      1 ->
        Enum.reduce(time_info, [], fn x, acc ->
          case x do
            x when is_binary(x) -> acc ++ [x]
            x when is_tuple(x) -> # Handl Kano Cinema weirdness
              case List.last(acc) do
                nil -> [x]
                y when is_binary(y) -> acc ++ [x]
                y when is_tuple(y) ->
                  {"strong", [],[day_range_start]} = y
                  # day_range_end is assumed to be "to <day>:"
                  # If it isn't, we're screwed
                  {"strong", [], [day_range_end]} = x
                  acc = List.delete_at(acc, -1)
                  day_range = String.trim(day_range_start) <> " " <> String.trim(day_range_end)
                  acc ++ [{"strong", [], [day_range]}]
              end
          end
        end)
    end
    |> Enum.chunk(2)
    |> Enum.map(fn
      [{"strong", [], [day_range]}, time_string] ->
        day_range = String.replace_prefix(day_range, "Late Night Show", "")
        String.trim(day_range) <> " " <> String.trim(time_string)
      [day_range, time_string] ->
        day_range = String.replace_prefix(day_range, "Late Night Show", "")
        String.trim(day_range) <> " " <> String.trim(time_string)
    end)
  end

  defp expand_time_string("Mon: " <> time_string), do: {"Mon", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Tue: " <> time_string), do: {"Tue", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Wed: " <> time_string), do: {"Wed", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Thu: " <> time_string), do: {"Thu", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Fri: " <> time_string), do: {"Fri", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Sat: " <> time_string), do: {"Sat", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string("Sun: " <> time_string), do: {"Sun", Utils.split_and_trim(time_string, ",")}
  defp expand_time_string(str) when is_binary(str) do
    [day_range, time_string] = Utils.split_and_trim(str, ":", [parts: 2])
    time_string = String.downcase(time_string)

    day_range
    |> expand_range
    |> Enum.map(&(expand_time_string(&1, time_string)))
  end
  defp expand_time_string(day, time_string), do: expand_time_string("#{day}: #{time_string}")

  defp expand_range(str) do
    case String.contains?(str, "to") do
      false ->
        case String.contains?(str, ",") do
          false -> [str]
          true -> Utils.split_and_trim(str, ",")
        end
      true ->
        [start, stop] = Utils.split_and_trim(str, "to")
        expand_range(start, stop, [])
    end
  end
  defp expand_range(stop, stop, acc), do: acc ++ [stop]
  defp expand_range(start, stop, []), do: expand_range(Utils.day_after(start), stop, [start])
  defp expand_range(day, stop, acc), do: expand_range(Utils.day_after(day), stop, acc ++ [day])
end

