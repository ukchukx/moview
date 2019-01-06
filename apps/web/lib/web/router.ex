defmodule Moview.Web.Router do
  use Moview.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Moview.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :movies
    get "/m/:slug", PageController, :movie
    get "/cinemas", PageController, :cinemas
    get "/a/movies", AdminController, :movies
    post "/a/add-movie", AdminController, :add_movie
    post "/a/delete-movie/:movie_id", AdminController, :delete_movie
    post "/a/add-schedule", AdminController, :add_schedule
    post "/a/delete-schedule/:schedule_id", AdminController, :delete_schedule
    post "/a/clear-schedules/:movie_id", AdminController, :clear_schedules
    get "/*path", PageController, :catch_all
  end

  # Other scopes may use custom stacks.
  # scope "/api", Moview.Web do
  #   pipe_through :api
  # end
end
