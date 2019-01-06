defmodule Moview.Web.Cache do
  alias __MODULE__.Impl

  def get_schedules(movie_id), do: Impl.get_schedules(movie_id)
  def refresh_schedules, do: Impl.refresh_schedules()
end
