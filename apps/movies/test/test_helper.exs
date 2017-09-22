ExUnit.start()

:ok = Ecto.Adapters.SQL.Sandbox.checkout(Moview.Movies.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Moview.Movies.Repo, {:shared, self()})

