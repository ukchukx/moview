defmodule Moview.AuthenticationTest do
  use ExUnit.Case
  alias Moview.Auth.Authentication, as: Auth
  alias Moview.Auth.User, as: API

  setup %{} do
    on_exit fn -> API.clear_state() end

    {:ok, %{id: id} = user} = API.create_user(%{email: "a@moview.com", role: "admin", password: "password"})
    {:ok, token} = Auth.create_token(id)

    {:ok, user: user, token: token}
  end

  test "auth user by email", %{user: %{data: %{email: email}}} do
    {:ok, %{data: %{email: uemail}}} = Auth.auth_by_email_and_pass(email, "password")
    assert email == uemail
    assert {:error, :auth_failed} == Auth.auth_by_email_and_pass(email, "passwor")
    assert {:error, :not_found} == Auth.auth_by_email_and_pass("b" <> email, "password")
  end

  test "create token", %{user: %{id: id}, token: token} do
    {:ok, uid} = Auth.decode_token(token)
    assert uid == id
  end

  test "auth user by token", %{user: %{id: id, data: %{email: email}}, token: token} do
    {:ok, %{id: uid, data: %{email: uemail}}} = Auth.auth_by_token(token)
    assert id == uid
    assert email == uemail

    assert {:error, :not_found} == Auth.create_token(1)
    assert {:error, :auth_failed} == Auth.auth_by_token("gibberish")
  end

end

