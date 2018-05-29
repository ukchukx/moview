defmodule Moview.Scraper.Genesis.Impl do
  require Logger
  alias Moview.Movies.{Movie, Schedule}
  alias Moview.Scraper.{Common, Utils}

  @weekdays  ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  @title_embellishments  ["(NEW)", "[3d]"]

  def do_scrape(cinemas) do
    cinemas
    |> Enum.map(fn %{data: %{url: url, address: a, branch_title: b}, id: cinema_id} ->
      Logger.info "Beginning to scrape: (#{b}) @ #{a}"
      Task.async(fn ->  
        scrape(url)
        |> Enum.map(&Common.create_or_return_movie/1)
        |> Enum.filter(fn
          %{movie: nil} -> false
          _ -> true
        end)
        |> Enum.map(fn %{movie: %{id: movie_id, data: %{title: title}}, times: times} ->
          Logger.debug("Fetching schedules to clear for movie #{title}")
          {:ok, schedules} = Schedule.get_schedules()
          deletion_candidates = Common.get_schedules_for_deletion(schedules, cinema_id, movie_id)
          Logger.debug "Found #{length deletion_candidates} schedules to be cleared for #{title}"

          Logger.debug("Creating schedules params for movie #{title}")
          schedule_params = Common.get_schedule_params(times, cinema_id, movie_id)
          Logger.debug "Found #{length schedule_params} schedules to be inserted for #{title}"

          Logger.debug "Deleting schedules..."
          Enum.each(deletion_candidates, &Schedule.delete_schedule/1)
          Logger.debug "Creating new schedules..."
          Enum.each(schedule_params, &Schedule.create_schedule/1)
        end)
      end)
    end)
    |> Enum.each(&Task.await(&1, 120_000))
  end

  defp scrape(url) do
    url
    |> Utils.make_request(false)
    |> case do
      {:ok, body} ->
        body
        |> Floki.find("section.container > div.col-sm-8.col-md-9 > div.movie.release")
        |> Enum.map(&movie_node/1)
        |> Enum.map(fn node ->
          Task.async(fn -> extract_info_from_node(node) end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.filter(fn
          nil -> false
          _ -> true
        end)

      {:error, _} -> %{error: "Did not get response"}
    end
  end

  defp extract_info_from_node(movie_node) do
    case movie_title(movie_node) do
      title when is_binary(title) ->
        Logger.debug "Extracted title: #{title}"
        Logger.debug "Extracting times for #{title}..."

        times =
          movie_node
          |> movie_time_strings
          |> Enum.map(&expand_time_string/1)
          |> List.flatten

        %{title: title, times: times}
      _ -> 
        Logger.warn "Could not extract_info_from_node"
        nil
    end
  end

  defp movie_node({_, _, nodes}), do:  Enum.at(nodes, 1)

  defp movie_title({_, _, [a_node |_]}) do
    case a_node do
      {"a", _, [title]} ->
        title
        |> Common.clean_title(@title_embellishments)
        |> String.trim
        |> String.downcase
        |> String.capitalize

      _ -> nil
    end
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

  defp expand_time_string("Daily: "<> time_string) do
    Logger.debug "Expanding (daily) time string: #{time_string}"
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
    Logger.debug "Expanding time string: #{str}"
    [day_range, time_string] = Utils.split_and_trim(str, ":", [parts: 2])
    [day_range, time_string] =
      case day_range do
        "Daily  12" -> ["Daily", "12:00pm " <> time_string]
        _ -> [day_range, time_string]
      end

    Utils.split_and_trim(day_range, ",")
    |> Enum.map(fn dr -> Utils.split_and_trim(dr, "&") |> Enum.map(&expand_range/1) end)
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
        Common.expand_range(start, stop, [])
    end
  end
end

