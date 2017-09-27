defmodule Moview.Movies.Cinema.Impl do
  import Moview.Movies.BaseSchema, only: [to_map: 1]

  alias Moview.Movies.Cinema.Schema, as: Cinema
  alias Moview.Movies.Repo

  @service_name Application.get_env(:movies, :services)[:cinema]

  def clear_state do
    delete_cinemas()
  end

  def create_cinema(%{name: name, address: addr, city: city} = params) do
    cinema_filter_fun = fn
      %{data: %{name: ^name, address: ^addr, city: ^city}} -> true
      _ -> false
    end

    case get_cinemas_by_name(name) do
      {:ok, []} ->
        do_create_cinema(params)
      {:ok, cinemas} ->
        case Enum.filter(cinemas, cinema_filter_fun) do
            [] ->
              do_create_cinema(params)
          [cinema] ->
            {:ok, cinema}
        end
    end
  end

  defp do_create_cinema(params) do
    case Cinema.changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        case Repo.insert!(changeset) do
          {:error, changeset} ->
            {:error, changeset}
          cinema ->
            GenServer.cast(@service_name, {:save_cinema, cinema})
            {:ok, cinema}
        end
      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}
    end
  end

  def update_cinema(id, %{} = params) do
    case get_cinema(id) do
      {:ok, cinema} ->
        case Cinema.changeset(cinema, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            case Repo.update!(changeset) do
              {:error, changeset} ->
                {:error, changeset}
              cinema ->
                GenServer.cast(@service_name, {:save_cinema, cinema})
                {:ok, cinema}
            end
          %Ecto.Changeset{valid?: false} = changeset ->
            {:error, changeset}
        end
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get_cinemas do
    case GenServer.call(@service_name, {:get_cinemas}) do
      {:ok, []} ->
        case Repo.all(Cinema) do
          [] ->
            {:ok, []}
          cinemas ->
            Enum.each(cinemas, fn cinema -> GenServer.cast(@service_name, {:save_cinema, cinema}) end)
            {:ok, cinemas}
        end
      {:ok, _cinemas} = res -> res
    end
  end

  def get_cinema(id) do
    case GenServer.call(@service_name, {:get_cinema, [id: id]}) do
      {:error, :not_found} = err ->
        case Repo.get(Cinema, id) do
          nil -> err
          cinema ->
            GenServer.cast(@service_name, {:save_cinema, cinema})
            {:ok, cinema}
        end
      {:ok, cinema} ->
        {:ok, cinema}
    end
  end

  def get_cinemas_by_name(name) do
    import Ecto.Query

    case GenServer.call(@service_name, {:get_cinemas, [name: name]}) do
      {:ok, []} = empty_result ->
        lname = String.downcase(name)
        case Repo.all(from r in Cinema, where: fragment("lower(data->>'name') = ?", ^lname)) do
          [] -> empty_result
          cinemas ->
            Enum.each(cinemas, fn cinema -> GenServer.cast(@service_name, {:save_cinema, cinema}) end)
            {:ok, cinemas}
        end
      {:ok, cinemas} ->
        {:ok, cinemas}
    end
  end

  def delete_cinema(%Cinema{id: id} = cinema) do
    GenServer.cast(@service_name, {:delete_cinema, [id: id]})
    {:ok, Repo.delete!(cinema)}
  end

  def delete_cinemas do
    GenServer.cast(@service_name, {:delete_cinemas})
    Repo.delete_all(Cinema)
  end


  defmodule Cache do
    use GenServer

    @service_name Application.get_env(:movies, :services)[:cinema]

    def start_link do
      cinemas = Repo.all(Cinema) |> to_map
      GenServer.start_link(__MODULE__, %{cinemas: cinemas}, name: @service_name)
    end

    def init(state) do
      {:ok, state}
    end

    def handle_call(:which_state, _, state), do: {:reply, state, state}

    def handle_call({:get_cinema, [id: id]}, _, %{cinemas: cinemas}) do
      case Map.get(cinemas, id) do
        nil ->
          {:reply, {:error, :not_found}, %{cinemas: cinemas}}
        cinema ->
          {:reply, {:ok, cinema}, %{cinemas: cinemas}}
      end
    end

    def handle_call({:get_cinemas, [name: name]}, _, %{cinemas: cinemas}) do
      name = String.downcase(name)
      results =
        cinemas
        |> Map.values
        |> Enum.filter(&(String.downcase(&1.data.name) == name))
      {:reply, {:ok, results}, %{cinemas: cinemas}}
    end

    def handle_call({:get_cinemas}, _, %{cinemas: cinemas}) do
      {:reply, {:ok, Map.values(cinemas)}, %{cinemas: cinemas}}
    end

    def handle_cast({:save_cinema, %{id: id} = cinema}, %{cinemas: cinemas}) do
      {:noreply, %{cinemas: Map.put(cinemas, id, cinema)}}
    end

    def handle_cast({:delete_cinema, [id: id]}, %{cinemas: cinemas}) do
      {:noreply, %{cinemas: Map.delete(cinemas, id)}}
    end

    def handle_cast({:delete_cinemas}, _state) do
      {:noreply, %{cinemas: %{}}}
    end
  end
end
