defmodule Moview.Scraper.Ozone.Impl do
  require Logger
  alias Moview.Movies.Schedule
  alias Moview.Scraper.{Common, Utils}

  @title_embellishments  ["NEW"]

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
        |> Floki.find("div.col-lg-7 > div.section_5")
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
      |> Common.expand_time_string
      |> List.flatten

    %{title: title, times: times}
  end

  defp movie_title({_, _, [div_node | _]}) do
    {"div", [{"class", "clearfix"} | _], [{"b", _, [{_, _, [title | _]}]} | _]} = div_node

    title
    |> Common.remove_multiple_white_spaces
    |> Common.clean_title(@title_embellishments)
    |> String.trim
    |> String.downcase
    |> String.capitalize
  end

  defp movie_time_string({_, _, [_ | nodes]}) do
    [{"div", [{"class", "post_text"}], [{"p", _, [_| nodes]}]}] = nodes

    {"span", _, [{"strong", _, [day_range]}]} = Enum.at nodes, 4
    day_range =
      day_range
      |> String.trim
      |> String.replace("Thur", "Thu")

    time_string =
      nodes
      |> Enum.at(5)
      |> Common.remove_multiple_white_spaces

    "#{day_range} #{time_string}"
  end

end
