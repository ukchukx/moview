defmodule Moview.CinemaTest do
  use ExUnit.Case

  alias Moview.Movies.Cinema, as: API


  setup %{} do
    on_exit fn -> API.clear_state() end

    API.init(true)
    {:ok, cinema} = API.create_cinema(%{name: "Movie cinemas", address: "#1 Theatre road", city: "Metro"})

    {:ok, cinema_params: %{name: "Blockbuster", address: "#2 Trailer park", city: "Polis"}, cinema: cinema}
  end

  test "create cinema", %{cinema_params: params = %{name: pn, city: pc, address: pa}} do
    {:ok, %{data: %{name: name, address: addr, city: city}, id: id}} = API.create_cinema(params)
    assert name == pn
    assert addr == pa
    assert city == pc
    assert is_integer(id)
  end

  test "create cinema with identical name, address & city when cinema exists",
    %{cinema: %{data: data = %{name: n, address: addr, city: c}, id: id}} do
    {:ok, %{id: rid, data: %{name: cn, address: ca, city: cc}}} = API.create_cinema(data)
    assert rid == id
    assert cn == n
    assert ca == addr
    assert cc == c

    {:ok, cinemas} = API.get_cinemas()
    assert 1 == Enum.count(cinemas)
  end

  test "update cinema", %{cinema: %{id: id}, cinema_params: params = %{name: n, city: c, address: a}} do
    {:ok, %{id: rid, data: %{name: name, address: address, city: city}}} = API.update_cinema(id, params)
    assert name == n
    assert city == c
    assert address == a
    assert rid == id
  end

  test "get a cinema", %{cinema: %{id: id, data: %{name: name}}} do
    {:ok, %{data: %{name: rname}}} = API.get_cinema(id)
    assert rname == name
  end

  test "get cinemas", %{cinema: %{id: id, data: %{name: name}}} do
    {:ok, cinemas} = API.get_cinemas()
    assert 1 == Enum.count(cinemas)

    %{id: rid, data: %{name: rname}} = Enum.at(cinemas, 0)
    assert rname == name
    assert rid == id
  end

  test "find cinemas by name", %{cinema_params: %{name: pname} = params, cinema: %{data: %{name: rname}, id: id}} do
    {:ok, [%{id: rid}]} = API.get_cinemas_by_name(rname)
    assert id == rid
    assert {:ok, []} == API.get_cinemas_by_name(pname)

    API.create_cinema(Map.put(params, :name, rname))
    {:ok, cinemas} = API.get_cinemas_by_name(rname)
    assert 2 == Enum.count(cinemas)
  end

  test "delete cinema", %{cinema: %{id: id} = cinema} do
    {:ok, %{id: rid}} = API.delete_cinema(cinema)
    assert rid == id
    assert {:error, :not_found} == API.get_cinema(id)
  end
end

