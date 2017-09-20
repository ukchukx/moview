defmodule Moview.Web.PageController do
  use Moview.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
