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
    get "/movie/:slug", PageController, :movie
    get "/cinemas", PageController, :cinemas
    get "/*path", PageController, :movies
  end

  # Other scopes may use custom stacks.
  # scope "/api", Moview.Web do
  #   pipe_through :api
  # end
end
