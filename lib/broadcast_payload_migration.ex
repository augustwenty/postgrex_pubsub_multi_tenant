defmodule PostgrexPubsubMultiTenant.BroadcastPayloadMigration do
  @moduledoc """
  A macro for applying mutation broadcast triggers to tables
  """

  defmacro __using__(opts) do
    table_name =
      opts
      |> Map.new()
      |> Map.get(:table_name)

    prefix =
      opts
      |> Map.new()
      |> Map.get(:prefix, "public")

    columns =
      opts
      |> Map.new()
      |> Map.get(:columns)

    quote do
      use Ecto.Migration

      def up do
        PostgrexPubsubMultiTenant.PayloadStrategy.broadcast_mutation_for_table(
          unquote(table_name),
          unquote(prefix),
          unquote(columns)
        )
      end

      def down do
        PostgrexPubsubMultiTenant.PayloadStrategy.delete_broadcast_trigger_for_table(
          unquote(table_name),
          unquote(prefix)
        )
      end
    end
  end
end
