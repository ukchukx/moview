defmodule Moview.Scraper.Utils do
  require Logger

  defp tmdb_url, do: Application.get_env(:scraper, :tmdb)[:base_url]
  defp tmdb_key, do: Application.get_env(:scraper, :tmdb)[:key]

  defp omdb_url, do: Application.get_env(:scraper, :omdb)[:base_url]
  defp omdb_key, do: Application.get_env(:scraper, :omdb)[:key]

  defp movie_search_query do
    "#{tmdb_url()}/search/movie?api_key=#{tmdb_key()}&language=en-US&page=1&include_adult=false"
  end

  @image_url_base "http://image.tmdb.org/t/p"

  @timeout 20_000
  @sleep_duration 2_000


  defp sleep_maybe(url) do
    # Sleep so we don't get caught by TMDB's rate limit
    if String.contains?(url, tmdb_url()) do
      Process.sleep(@sleep_duration)
    end
  end

  def make_request(url, decode \\ true) do
    Task.async(fn -> sleep_maybe(url) end) |> Task.await

    Logger.debug "Fetching #{blank_out(url, [omdb_key(), tmdb_key()])}"
    
    case HTTPotion.get(url, [timeout: @timeout]) do
      %HTTPotion.Response{} = resp ->
        body = gunzip_maybe(resp)

        case decode do
          true ->
            {:ok, Poison.decode!(body)}
          false ->
            {:ok, body}
        end

      %HTTPotion.ErrorResponse{} = resp ->
        Logger.error "Request error: #{inspect resp}"
        {:error, :no_response}
    end
  end

  # Passing trim: true to String.split doesn't work for some reason
  def split_and_trim(str, delim, opts \\ [trim: true]), do: String.split(str, delim, opts) |> Enum.map(&String.trim/1)


  def get_image_url(width, image) do
    case String.contains?(image, "/") do
      true ->
        "#{@image_url_base}/#{width}#{image}"
      false ->
        "#{@image_url_base}/#{width}/#{image}"
    end
  end
  def get_image_url(image), do: get_image_url("w342", image)
  # "w92", "w154", "w185", "w342", "w500", "w780"


  def get_movie_details(""), do: {:error, nil}
  def get_movie_details(title) when is_binary(title) do
    case search_for_movie(title) do
      {:error, _} = err -> err
      {:ok, %{"id" => id}} ->
        {:ok, %{"id" => ^id, "imdb_id" => imdb_id, "genres" => genres} = movie} =
          id
          |> movie_query
          |> make_request

        trailer = get_trailer(movie["videos"]["results"])
        genres = Enum.map(genres, &(&1["name"])) # We only need their names
        release_date_tup = 
          movie["release_date"] # yyyy-mm-dd
          |> String.split("-")
          |> Enum.map(&String.to_integer/1)
          |> List.to_tuple

        release_date = :calendar.datetime_to_gregorian_seconds({release_date_tup,{0,0,0}}) - 62167219200 |> Kernel.*(1000)

        case imdb_id do
          nil -> {:error, :no_imdb_id}
          _ ->
            case get_other_info(imdb_id) do
              {:ok, %{rating: rating, stars: stars, synopsis: synopsis} } ->
                # Choose longer synopsis
                synopsis = Enum.max_by([synopsis, movie["overview"]], &(String.length(&1)), fn -> nil end)

                {:ok, %{
                  genres: genres,
                  rating: rating,
                  trailer: trailer,
                  stars: stars,
                  title: movie["title"],
                  poster: get_image_url(movie["poster_path"]),
                  runtime: movie["runtime"],
                  release_date: release_date,
                  synopsis: synopsis}}
                
              err -> err
            end
        end
    end
  end
  def get_movie_details(_), do: {:error, nil}

  def day_after("Mon"), do: "Tue"
  def day_after("Tue"), do: "Wed"
  def day_after("Wed"), do: "Thu"
  def day_after("Thu"), do: "Fri"
  def day_after("Fri"), do: "Sat"
  def day_after("Sat"), do: "Sun"
  def day_after("Sun"), do: "Mon"

  def full_day("Mon"), do: "Monday"
  def full_day("Tue"), do: "Tuesday"
  def full_day("Wed"), do: "Wednesday"
  def full_day("Thu"), do: "Thursday"
  def full_day("Fri"), do: "Friday"
  def full_day("Sat"), do: "Saturday"
  def full_day("Sun"), do: "Sunday"


  defp get_other_info(imdb_id) when is_binary(imdb_id) do
    case make_request("#{omdb_url()}?apiKey=#{omdb_key()}&i=#{imdb_id}&plot=full") do
      {:ok, %{"Response" => "True", "Rated" => rating, "Actors" => stars, "Plot" => plot}} ->
        {:ok, %{rating: rating, stars: split_and_trim(stars, ","), synopsis: plot}}
      _ -> {:error, "err_details"}
    end
  end
  defp get_other_info(_), do: {:error, "err_details"}


  defp get_trailer(video_list) when is_list(video_list) do
    most_probable_trailer =
      video_list
      # Get videos with type: Trailer and site: YouTube and has 'Trailer' in its name
      |> Enum.filter(fn
        %{"name" => name, "type" => "Trailer", "site" => "YouTube"} -> String.contains?(name, "Trailer")
        _ -> false
      end)
      # The one with the shortest title is probably it
      |> Enum.min_by(&(String.length(&1["name"])), fn -> nil end)

    case most_probable_trailer do
      nil -> get_trailer(nil)
      video -> "https://www.youtube.com/embed/#{video["key"]}"
    end
  end
  defp get_trailer(_), do: ""


  defp movie_query(id), do: "#{tmdb_url()}/movie/#{id}?api_key=#{tmdb_key()}&language=en-US&append_to_response=videos"


  defp search_for_movie(title) do
    encoded_title =
      title
      |> String.downcase
      |> URI.encode

    {:ok, %{"results" => results}} = make_request("#{movie_search_query()}&query=#{encoded_title}")
    case results do
      [] -> {:error, :found_nothing}
      _ ->
        # Weed out unnecessary results
        results =
          results
          |> Enum.filter(fn
            %{"release_date" => ""} -> false
            %{"poster_path" => nil} -> false
            %{"poster_path" => ""} -> false
            %{"vote_count" => 0} -> false
            %{"genre_ids" => stuff} -> is_list(stuff) && Enum.count(stuff) > 0
            _ -> true
          end)

        {{year, _, _}, _} = :calendar.local_time()
        this_year = "#{year}"
        last_year = "#{year - 1}"

        # Do we have any release this year?
        this_year_available =
          results
          |> Enum.any?(fn %{"release_date" => release_date} ->
            <<release_year ::binary-size(4)>> <> _ = release_date
            release_year == this_year
          end)

        results
        # Look for this year or last year releases
        |> Enum.filter(fn
          %{"release_date" => release_date} ->
            <<release_year :: binary-size(4)>> <> _ = release_date
            if this_year_available do
              release_year == this_year
            else
              release_year == last_year
            end
          _ -> false
        end)
        |> case do
          [] -> nil
          [one] -> one
          _ = res ->
            # If more than one was returned, remove results whose titles are longer than ours...
            # then look for the most popular
            res
            |> Enum.filter(fn %{"title" => t} -> String.length(t) == String.length(title) end)
            |> Enum.max_by(fn %{"vote_count" => x} -> x end, fn -> nil end)
        end
        |> case do
          nil -> {:error, nil}
          res -> {:ok, res}
        end
     end
  end


  defp gunzip_maybe(%HTTPotion.Response{body: body, status_code: 200,
    headers: %HTTPotion.Headers{hdrs: headers}}) do
    case headers do
      %{"content-encoding" => "gzip"} ->
        :zlib.gunzip(body)
      _ ->
        body
    end
  end
  defp gunzip_maybe(resp), do: resp


  defp blank_out(string, []), do: string
  defp blank_out(string, [head|rest]) do
    case head do
      nil -> blank_out(string, rest)
      "" -> blank_out(string, rest)
      _ ->
        if Application.get_env(:scraper, :env) == :prod do
          blank_out(String.replace(string, head, "******"), rest)
        else
          blank_out(string, rest)
        end
    end
  end

end
