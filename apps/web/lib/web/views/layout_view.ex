defmodule Moview.Web.LayoutView do
  use Moview.Web, :view


  def home_link(conn), do: page_path(conn, :movies)
  def cinemas_link(conn), do: page_path(conn, :cinemas)

  @doc """
    Generates name for the JavaScript view we want to use
    in this combination of view/template.
  """
  def js_view_name(conn, view_template) do
    [view_name(conn), template_name(view_template)]
    |> Enum.reverse
    |> List.insert_at(0, "view")
    |> Enum.map(&(Enum.map(String.split(&1, "_"), fn string -> String.capitalize(string) end)))
    |> Enum.reverse
    |> Enum.join("")
  end

  # Takes the resource name of the view module and removes the ending *_view* string.
  defp view_name(conn) do
    conn
    |> view_module
    |> Phoenix.Naming.resource_name
    |> String.replace("_view", "")
  end

  # Removes the extion from the template and returns just the name.
  defp template_name(template) when is_binary(template) do
    template
    |> String.split(".")
    |> Enum.at(0)
  end
end
