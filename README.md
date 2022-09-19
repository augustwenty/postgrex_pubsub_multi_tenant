# PostgrexPubsubMultiTenant

This is a package for easily adding a Postgres based pubsub system to your phoenix application.

## Installation

If [available in Hex](https://hex.pm/postgrex_pubsub_multi_tenant), the package can be installed
by adding `postgrex_pubsub_multi_tenant` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postgrex_pubsub_multi_tenant, "~> 0.2.4"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://github.com/augustwenty/postgrex_pubsub_multi_tenant](https://github.com/augustwenty/postgrex_pubsub_multi_tenant).

## Payload Based Usage

### 1. Apply the Postgres triggers to a table
1. Create an empy migration
```bash
mix ecto.gen.migration broadcast_users_mutation
```

2. Use the `BroadcastMigration` macro
```ex
defmodule YourApp.Repo.Migrations.BroadcastUsersMutation do
  use PostgrexPubsubMultiTenant.BroadcastPayloadMigration, table_name: "users"
end
```

3. Migrate
```bash
mix ecto. migrate
```

### 2. Create a listener
```ex
defmodule YourApp.Listeners.Email do
  use PostgrexPubsubMultiTenant.Listener, repo: YourApp.Repo

  def handle_mutation_event(%{
    "id" => row_id,
    "new_row_data" => new_row_data,
    "old_row_data" => old_row_data,
    "table" => table,
    "type" => type, # "INSERT", "UPDATE"
  } = payload) do
    IO.inspect(payload, label: "payload")
  end
end
```

### 3. Attach the listener
```ex
# application.ex
defmodule YourApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ...
      YourApp.Listeners.Email,
    ]
    # ...
    Supervisor.start_link(children, opts)
  end

  # ...
end
```

### 4. Test it out!
Now when inserting or updating a user you should see the following in your terminal
```bash
payload: %{
  "id" => "b3e041a5-2d6e-4f6f-9afc-64f326d3227f",
  "new_row_data" => %{
    "email" => "email@email.com",
    "id" => "b3e041a5-2d6e-4f6f-9afc-64f326d3227f",
    "inserted_at" => "2020-03-30T19:40:17",
    "name" => "Ben Church",
    "stripe_customer_id" => "cus_H0USudjt8o4cuS",
    "updated_at" => "2020-03-30T19:41:16"
  },
  "old_row_data" => %{
    "email" => "email@email.com",
    "id" => "b3e041a5-2d6e-4f6f-9afc-64f326d3227f",
    "inserted_at" => "2020-03-30T19:40:17",
    "name" => "Ben Church",
    "updated_at" => "2020-03-30T19:40:17"
  },
  "table" => "users",
  "type" => "UPDATE"
}
```


## ID Based Usage
__Usefull as pg_notify has a hard limit of 8000 bytes__
### 1. Apply the Postgres triggers to a table
1. Create an empy migration
```bash
mix ecto.gen.migration broadcast_users_mutation
```

2. Use the `BroadcastMigration` macro
```ex
defmodule YourApp.Repo.Migrations.BroadcastUsersMutation do
  use PostgrexPubsubMultiTenant.BroadcastIdMigration, table_name: "users"
end
```

3. Migrate
```bash
mix ecto. migrate
```

### 2. Create a listener
```ex
defmodule YourApp.Listeners.Email do
  use PostgrexPubsubMultiTenant.Listener, repo: YourApp.Repo

  def handle_mutation_event(%{
    "id" => row_id,
    "table" => table,
    "type" => type, # "INSERT", "UPDATE"
  } = payload) do
    IO.inspect(row_id, label: "row_id")
  end
end
```

### 3. Attach the listener
```ex
# application.ex
defmodule YourApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ...
      YourApp.Listeners.Email,
    ]
    # ...
    Supervisor.start_link(children, opts)
  end

  # ...
end
```

### 4. Test it out!
Now when inserting or updating a user you should see the following in your terminal
```bash
row_id: %{
  "id" => "b3e041a5-2d6e-4f6f-9afc-64f326d3227f",
  "table" => "users",
  "type" => "UPDATE"
}
```

