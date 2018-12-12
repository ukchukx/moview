defmodule Moview.ScheduleTest do
  use ExUnit.Case

  alias Moview.Movies.Schedule, as: API
  alias Moview.Movies.Cinema, as: CinemaAPI
  alias Moview.Movies.Movie, as: MovieAPI


  setup %{} do
    on_exit fn ->
      API.clear_state()
      CinemaAPI.clear_state()
      MovieAPI.clear_state()
    end

    {:ok, cinema} = CinemaAPI.create_cinema(%{name: "Movie cinemas", address: "#1 Theatre road", city: "Metro"})
    {:ok, %{data: %{name: genre}}} = MovieAPI.create_genre(%{name: "Action"})
    {:ok, %{data: %{name: rating}}} = MovieAPI.create_rating(%{name: "PG"})

    {:ok, movie} =
      %{title: "Action film",
        runtime: 90,
        release_date: 1234567890,
        poster: "action-film.jpg",
        trailer: "https://youtube.com/watch?v=action-film",
        rating: rating,
        stars: ["Actor A", "Actor B"],
        genres: [genre]} |> MovieAPI.create_movie

    {:ok, schedule} = API.create_schedule(
      %{movie_id: movie.id, cinema_id: cinema.id, day: "Monday", time: "18:00", schedule_type: "3D"})

      schedule_params = %{movie_id: movie.id, cinema_id: cinema.id, day: "friday", time: "12:00", schedule_type: "2D"}

    {:ok, schedule_params: schedule_params, schedule: schedule}
  end

  test "create schedule", %{schedule_params: params} do
    {:ok, %{data: %{schedule_type: st, day: day}, id: id}} = API.create_schedule(params)
    assert day == "Friday"
    assert st == "2D"
    assert is_integer(id)

    params =
      params
      |> Map.put(:movie_id, 1)
      |> Map.put(:cinema_id, 1)
    assert {:error, %{movie_id: :not_found, cinema_id: :not_found}} == API.create_schedule(params)
  end

  test "create schedule with identical name, address & city when schedule exists",
    %{schedule: %{data: data = %{day: d, time: t, schedule_type: s}, id: id, movie_id: mid, cinema_id: cid}} do
    data =
      data
      |> Map.take([:day, :schedule_type, :time])
      |> Map.merge(%{cinema_id: cid, movie_id: mid})

    {:ok, %{id: rid, data: %{day: sd, time: st, schedule_type: ss}}} = API.create_schedule(data)
    assert sd == d
    assert st == t
    assert ss == s
    assert rid == id

    {:ok, schedules} = API.get_schedules()
    assert 1 == Enum.count(schedules)
  end

  test "update schedule", %{schedule: %{id: id}, schedule_params: params} do
    {:ok, %{id: rid, data: %{day: day, time: time, schedule_type: stype}}} = API.update_schedule(id, params)
    assert day == String.capitalize(params.day)
    assert time == params.time
    assert stype == params.schedule_type
    assert rid == id
  end

  test "get a schedule", %{schedule: %{id: id, data: %{day: d, time: t}, movie_id: m, cinema_id: c}} do
    {:ok, %{data: %{day: day, time: time}, movie_id: mid, cinema_id: cid}} = API.get_schedule(id)
    assert d == day
    assert t == time
    assert m == mid
    assert c == cid
  end

  test "get schedules", %{schedule: %{id: id, data: %{day: day}}} do
    {:ok, schedules} = API.get_schedules()
    assert 1 == Enum.count(schedules)

    %{id: rid, data: %{day: d}} = Enum.at(schedules, 0)
    assert d == day
    assert rid == id
  end

  test "find schedules by day and cinema",
    %{schedule_params: %{day: pday}, schedule: %{data: %{day: day}, cinema_id: cid}} do
    {:ok, schedules} = API.get_schedules_by_day_and_cinema_id(pday, cid)
    assert 0 == Enum.count(schedules)

    {:ok, schedules} = API.get_schedules_by_day_and_cinema_id(day, cid)
    assert 1 == Enum.count(schedules)
  end

  test "find schedules by day and movie",
    %{schedule_params: %{day: pday}, schedule: %{data: %{day: day}, movie_id: mid}} do
    {:ok, schedules} = API.get_schedules_by_day_and_movie_id(pday, mid)
    assert 0 == Enum.count(schedules)

    {:ok, schedules} = API.get_schedules_by_day_and_movie_id(day, mid)
    assert 1 == Enum.count(schedules)
  end

  test "find schedules by movie", %{schedule: %{movie_id: mid}} do
    {:ok, schedules} = API.get_schedules_by_movie(0)
    assert 0 == Enum.count(schedules)

    {:ok, schedules} = API.get_schedules_by_movie(mid)
    assert 1 == Enum.count(schedules)
  end

  test "find schedules by cinema", %{schedule: %{cinema_id: cid}} do
    {:ok, schedules} = API.get_schedules_by_cinema(cid)
    assert 1 == Enum.count(schedules)

    {:ok, schedules} = API.get_schedules_by_cinema(0)
    assert 0 == Enum.count(schedules)
  end

  test "delete schedule", %{schedule: %{id: id} = schedule} do
    {:ok, %{id: rid}} = API.delete_schedule(schedule)
    assert rid == id
    assert {:error, :not_found} == API.get_schedule(id)
  end
end

