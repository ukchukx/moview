defmodule Moview.Auth.User.Impl do
  import Ecto.Query

  alias Moview.Auth.Repo
  alias Moview.Auth.User.Schema, as: User

  @service_name Application.get_env(:auth, :services)[:user]

  defp email_query(email), do: from u in User, where: fragment("lower(data->>'email') = ?", ^email)

  def clear_state do
    delete_users()
  end

  def create_user(%{email: email, role: _, password: _} = params) do
    params = fix_role(params)

    case email |> email_query |> Repo.one do
      nil ->
        case User.changeset(params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.insert!(changeset) do
              {:error, _changeset} = err -> err
              user ->
                GenServer.cast(@service_name, {:save_user, user})
                {:ok, user}
            end
          %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
        end
      _ -> {:error, :email_taken}
    end
  end

  def update_user(id, %{email: email} = params) do
    params = fix_role(params)
    case get_user(id) do
      {:ok, %{data: %{email: ^email}} = user} -> do_update_user(user, params)
      {:ok, user} ->
        case email |> email_query |> Repo.one do
          nil -> do_update_user(user, params)
          _ -> {:error, :email_taken}
        end
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def update_user(id, %{} = params) do
    params = fix_role(params)
    case get_user(id) do
      {:ok, user} -> do_update_user(user, params)
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp fix_role(%{role: role} = params) do
    case role do
      "admin" -> params
      _ -> Map.put(params, :role, "user")
    end
  end
  defp fix_role(params), do: params

  defp do_update_user(user, params) do
    case User.changeset(user, params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        case Repo.update!(changeset) do
          {:error, changeset} -> {:error, changeset}
          user ->
            GenServer.cast(@service_name, {:save_user, user})
            {:ok, user}
        end
      %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
    end
  end

  def get_user(id) do
    case GenServer.call(@service_name, {:get_user, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(User, id) do
          nil -> err
          user ->
            GenServer.cast(@service_name, {:save_user, user})
            {:ok, user}
        end
      {:ok, _user} = res -> res
    end
  end

  def get_user_by_email(email) do
    case GenServer.call(@service_name, {:get_user, [email: email]}) do
      {:error, :not_found} = empty_result ->
        case email |> email_query |> Repo.one do
          nil -> empty_result
          user ->
            GenServer.cast(@service_name, {:save_user, user})
            {:ok, user}
        end
      {:ok, users} ->
        {:ok, users}
    end
  end

  def get_users do
    case GenServer.call(@service_name, {:get_users}) do
      {:ok, []} ->
        case Repo.all(User) do
          [] ->
            {:ok, []}
          users ->
            Enum.each(users, fn user -> GenServer.cast(@service_name, {:save_user, user}) end)
            {:ok, users}
        end
      {:ok, _users} = res -> res
    end
  end

  def delete_user(%User{id: id} = user) do
    GenServer.cast(@service_name, {:delete_user, [id: id]})
    {:ok, Repo.delete!(user)}
  end

  def delete_users do
    GenServer.cast(@service_name, {:delete_users})
    Repo.delete_all(User)
  end


  defmodule Cache do
    use GenServer

    import Moview.Auth.User, only: [to_map: 1]

    @service_name Application.get_env(:auth, :services)[:user]

    def start_link do
      users = Repo.all(User) |> to_map
      GenServer.start_link(__MODULE__, %{users: users}, name: @service_name)
    end

    def init(state) do
      {:ok, state}
    end

    def handle_call({:get_user, [id: id]}, _, %{users: users}) do
      case Map.get(users, id) do
        nil ->
          {:reply, {:error, :not_found}, %{users: users}}
        user ->
          {:reply, {:ok, user}, %{users: users}}
      end
    end

    def handle_call({:get_user, [email: email]}, _, %{users: users}) do
      results =
        users
        |> Map.values
        |> Enum.filter(&(&1.data.email == email))

      case results do
        [] -> {:reply, {:error, :not_found}, %{users: users}}
        [user] -> {:reply, {:ok, user}, %{users: users}}
      end
    end

    def handle_call({:get_users}, _, %{users: users}) do
      {:reply, {:ok, Map.values(users)}, %{users: users}}
    end

    def handle_cast({:save_user, %{id: id} = user}, %{users: users}) do
      {:noreply, %{users: Map.put(users, id, user)}}
    end

    def handle_cast({:delete_user, [id: id]}, %{users: users}) do
      {:noreply, %{users: Map.delete(users, id)}}
    end

    def handle_cast({:delete_users}, _) do
      {:noreply, %{users: %{}}}
    end
  end
end
