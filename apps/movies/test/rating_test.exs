defmodule Moview.RatingTest do
  use ExUnit.Case

  alias Moview.Movies.Movie, as: API


  setup %{} do
    API.clear_state()
    API.Impl.init(true)
    {:ok, rating} = API.create_rating(%{name: "r"})

    {:ok, rating_params: %{name: "pg-13"}, rating: rating}
  end

  test "create rating", %{rating_params: params} do
    {:ok, %{data: %{name: name}, id: id}} = API.create_rating(params)
    assert name == "PG-13"
    assert is_integer(id)
  end

  test "create rating when rating exists", %{rating: %{data: data, id: id}} do
    {:ok, %{data: %{name: name}, id: rid}} = API.create_rating(data)
    assert name == "R"
    assert rid == id
  end

  @tag :assoc
  test "update rating", %{rating: %{id: id}} do
    {:ok, %{id: rid, data: %{name: name}}} = API.update_rating(id, %{name: "t"})
    assert name == "T"
    assert rid == id
  end

  test "get a rating", %{rating: %{id: id, data: %{name: name}}} do
    {:ok, %{data: %{name: rname}}} = API.get_rating(id)
    assert rname == name
  end

  test "get ratings", %{rating: %{id: id, data: %{name: name}}} do
    {:ok, ratings} = API.get_ratings()
    assert 1 == Enum.count(ratings)

    %{id: rid, data: %{name: rname}} = Enum.at(ratings, 0)
    assert rname == name
    assert rid == id
  end

  test "find rating by name", %{rating_params: %{name: pname}, rating: %{data: %{name: rname}, id: id}} do
    {:ok, %{id: rid}} = API.get_rating_by_name(rname)
    assert id == rid
    assert {:error, :not_found} == API.get_rating_by_name(pname)
  end

  test "delete rating", %{rating: %{id: id} = rating} do
    {:ok, %{id: rid}} = API.delete_rating(rating)
    assert rid == id
    assert {:error, :not_found} == API.get_rating(id)
  end
end

