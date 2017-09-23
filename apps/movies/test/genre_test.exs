defmodule Moview.GenreTest do
  use ExUnit.Case

  alias Moview.Movies.Movie, as: API


  setup %{} do
    on_exit fn -> API.clear_state() end

    API.Impl.init(true)
    {:ok, genre} = API.create_genre(%{name: "action"})

    {:ok, genre_params: %{name: "thriller"}, genre: genre}
  end

  test "create genre", %{genre_params: params} do
    {:ok, %{data: %{name: name}, id: id}} = API.create_genre(params)
    assert name == "Thriller"
    assert is_integer(id)
  end

  test "create genre when genre exists", %{genre: %{data: data, id: id}} do
    {:ok, %{data: %{name: name}, id: gid}} = API.create_genre(data)
    assert name == "Action"
    assert gid == id
  end

  @tag :assoc
  test "update genre", %{genre: %{id: id}} do
    {:ok, %{id: gid, data: %{name: name}}} = API.update_genre(id, %{name: "t"})
    assert name == "T"
    assert gid == id
  end

  test "get a genre", %{genre: %{id: id, data: %{name: name}}} do
    {:ok, %{data: %{name: gname}}} = API.get_genre(id)
    assert gname == name
  end

  test "get genres", %{genre: %{id: id, data: %{name: name}}} do
    {:ok, genres} = API.get_genres()
    assert 1 == Enum.count(genres)

    %{id: gid, data: %{name: gname}} = Enum.at(genres, 0)
    assert gname == name
    assert gid == id
  end

  test "find genre by name", %{genre_params: %{name: pname}, genre: %{data: %{name: gname}, id: id}} do
    {:ok, %{id: gid}} = API.get_genre_by_name(gname)
    assert id == gid
    assert {:error, :not_found} == API.get_genre_by_name(pname)
  end

  test "delete genre", %{genre: %{id: id} = genre} do
    {:ok, %{id: gid}} = API.delete_genre(genre)
    assert gid == id
    assert {:error, :not_found} == API.get_genre(id)
  end
end


