defmodule Moview.Auth.Authentication do
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Joken, only: [token: 1, verify: 1, with_signer: 2, sign: 1, get_compact: 1, hs256: 1]
  import Moview.Auth.User, only: [get_user_by_email: 1, get_user: 1]

  @secret "_auth_secret"
  @signer hs256(@secret)

  @auth_failed {:error, :auth_failed}
  @not_found {:error, :not_found}

  def auth_by_email_and_pass(email, pass) do
    case get_user_by_email(email) do
      {:ok, user = %{data: %{password_hash: phash}}} ->
        case checkpw(pass, phash) do
          true -> {:ok, user}
          false -> @auth_failed
        end
      @not_found ->
        dummy_checkpw()
        @not_found
    end
  end

  def auth_by_token(token) do
    case decode_token(token) do
      {:ok, nil} -> @auth_failed
      {:error, _} -> @auth_failed
      {:ok, user_id} ->
        case get_user(user_id) do
          @not_found -> @not_found
          {:ok, _user} = res -> res
        end
    end
  end

  def create_token(id) do
    case get_user(id) do
      {:error, :not_found} = err -> err
      {:ok, %{id: id} = _} ->
        token =
          %{"id" => id}
          |> token
          |> with_signer(@signer)
          |> sign
          |> get_compact

        {:ok, token}
    end
  end

  def decode_token(token_str) do
    decoded_token =
      token_str
      |> token
      |> with_signer(@signer)
      |> verify

    case decoded_token do
      %{errors: [], claims: user_claims} -> {:ok, user_claims["id"]}
      _ -> {:error, "could not retrieve claims"}
    end
  end
end
