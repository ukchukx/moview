ExUnit.start()

:ok = Ecto.Adapters.SQL.Sandbox.checkout(Moview.Auth.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Moview.Auth.Repo, {:shared, self()})

