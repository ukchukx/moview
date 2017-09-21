defmodule Moview.Movies.Cinema.Server do
  use GenServer

  alias Moview.Movies.Cinema.Schema, as: Cinema
  alias Moview.Movies.Repo

  def start_link(state \\ %{cinemas: []}) do
    GenServer.start_link(__MODULE__, state, name: {:global, :cinema_service})
  end

  def init(state) do
    send(self(), :init_store)
    {:ok, state}
  end

  def handle_call({:create_cinema, %Cinema{} = cinema}, _from, %{cinemas: cinemas} = state) do
    case Repo.insert!(cinema) do
      {:ok, cinema} ->
        {:reply, {:ok, cinema}, %{cinemas: [cinema | cinemas]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:update_cinema, %Cinema{id: id} = cinema}, _from, %{cinemas: cinemas} = state) do
    case Repo.update!(cinema) do
      {:ok, cinema} ->
        {:reply, {:ok, cinema}, %{cinemas: [cinema | Enum.filter(cinemas, &(&1.id != id))]}}
      {:error, ch} ->
        {:reply, {:error, ch}, state}
    end
  end

  def handle_call({:get_cinema, [id: id]}, _from, %{cinemas: cinemas} = state) do
    case Enum.find(cinemas, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      cinema ->
        {:reply, {:ok, cinema}, state}
    end
  end

  def handle_call({:get_cinemas, [name: name]}, _from, %{cinemas: cinemas} = state) do
    {:reply, {:ok, Enum.filter(cinemas, &(&1.data.name == name))}, state}
  end

  def handle_call({:get_cinemas}, _from, %{cinemas: cinemas} = state) do
    {:reply, {:ok, cinemas}, state}
  end

  def handle_call({:delete_cinema, [id: id]}, _from, %{cinemas: cinemas} = state) do
    case Enum.find(cinemas, &(&1.id == id)) do
      nil ->
        {:reply, {:error, :not_found}, state}
      cinema ->
        Repo.delete!(cinema)
        {:reply, {:ok, cinema}, %{cinemas: Enum.filter(cinemas, &(&1.id != id))}}
    end
  end

  def handle_info(:init_store, %{cinemas: _} = state) do
    cinemas = Repo.all(Cinema)
    {:noreply, %{cinemas: cinemas}}
  end

end

