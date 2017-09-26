defmodule Moview.UserTest do
  use ExUnit.Case
  alias Moview.Auth.User, as: API

  setup %{} do
    on_exit fn -> API.clear_state() end

    {:ok, user} = API.create_user(%{email: "a@moview.com", role: "admin", password: "password"})

    {:ok, user: user, params: %{email: "b@moview.com", role: "whatever", password: "password1"}}
  end

  test "create user", %{params: params} do
    {:error, changeset} = API.create_user(Map.put(params, :password, "pass"))
    refute changeset.valid?

    {:ok, %{data: %{role: role}, id: id}} = API.create_user(params)
    assert role == "user"
    assert is_integer(id)

    assert {:error, :email_taken} == API.create_user(params)
  end

  test "update user",
    %{params: %{email: pemail} = params, user: %{id: id, data: %{email: uemail, password_hash: ohash}}} do
    {:ok, %{id: ^id, data: %{email: email, role: role, password_hash: phash}}} =
      API.update_user(id, Map.delete(params, :password))
    assert email == pemail
    assert role == "user"
    assert phash == ohash

    {:ok, %{id: ^id, data: %{email: email, password_hash: phash2}}} =
      API.update_user(id, %{email: uemail, password: "another password"})
    assert email == uemail
    refute phash == phash2
  end

  test "get user", %{user: %{id: id, data: %{email: email}}} do
    {:ok, %{id: uid, data: %{email: uemail}}} = API.get_user(id)
    assert id == uid
    assert email == uemail

    assert {:error, :not_found} == API.get_user(1)
  end

  test "get user by email", %{params: %{email: pemail}, user: %{data: %{email: email}, id: id}} do
    {:ok, %{id: uid, data: %{email: uemail}}} = API.get_user_by_email(email)
    assert uid == id
    assert uemail == email

    assert {:error, :not_found} == API.get_user_by_email(pemail)
  end

  test "get users", %{user: %{id: id, data: %{email: email}}} do
    {:ok, users} = API.get_users()
    assert 1 == Enum.count(users)

    %{id: uid, data: %{email: uemail}} = Enum.at(users, 0)
    assert uid == id
    assert email == uemail
  end

  test "delete user", %{user: %{id: id} = user} do
    {:ok, %{id: uid}} = API.delete_user(user)
    assert uid == id
    assert {:error, :not_found} == API.get_user(id)
  end

end

