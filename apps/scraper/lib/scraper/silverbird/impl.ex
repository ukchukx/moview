defmodule Moview.Scraper.Silverbird.Impl do
  require Logger
  alias Moview.Movies.Schedule
  alias Moview.Scraper.{Common, Utils}

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
        |> Floki.find(".entry-item > .entry-content")
        |> Enum.filter(fn node -> # Remove nodes without showtimes
          node
          |> Floki.raw_html
          |> String.contains?("COMING SOON")
          |> Kernel.==(false)
        end)
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
    title = movie_title(movie_node)
    Logger.debug "Extracted title: #{title}"
    Logger.debug "Extracting times..."

    times =
      movie_node
      |> movie_time_string
      |> List.flatten
      |> Enum.map(&expand_time_string/1)
      |> List.flatten

    %{title: title, times: times}
  end

  defp movie_title({_, _, [title_node | _]}) do
    {"h4", _, [{"a", _, [title]} | _]} = title_node

    title 
    |> Common.remove_multiple_white_spaces
    |> String.downcase
    |> String.capitalize
  end

  defp movie_time_string(movie_node) do
    [{"p", _, [_| tail]}] = 
      movie_node
      |> Floki.raw_html
      |> Floki.find(".cinema_page_showtime")
    
    tail
    |> Enum.reduce([], fn 
      ({"br", _, _}, acc) -> 
        acc

      ({"span", _, [{"strong", [], [day_string]}]}, acc) -> 
        day_string = 
          day_string
          |> String.replace("FR-", "FRI-")
          |> String.replace("FR,", "FRI,")
          |> String.replace("THUR", "THU")
          |> String.trim

        List.insert_at(acc, -1, day_string)

      ({"strong", _, [time_string]}, acc) -> 
        day_string = Enum.at(acc, -1)
         List.replace_at(acc, -1, "#{day_string} #{String.trim(time_string)}")
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

    Logger.debug "Expanding time string: #{str}"

    [day_range, time_string] = Utils.split_and_trim(str, ":", [parts: 2])
    time_string = String.downcase(time_string)

    day_range
    |> normalize_range
    |> Enum.map(fn range ->  
      range
      |> expand_range
      |> Enum.map(&(expand_time_string(&1, time_string)))
      |> List.flatten
    end)
    |> List.flatten
  end
  defp expand_time_string(day, time_string), do: expand_time_string("#{day}: #{time_string}")

  defp normalize_range(range) do
    range
    |> Utils.split_and_trim(",")
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
