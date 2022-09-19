defmodule PostgrexPubsubMultiTenant do
  @moduledoc """
  Documentation for `PostgrexPubsubMultiTenant`.
  """

  def default_channel, do: Application.get_env(:postgrex_pubsub, :channel) || "pg_mutations"

  def create_table_mutation_trigger_sql_INSERT_DELETE(
        table_name,
        prefix,
        trigger_name,
        function_name
      ) do
    "CREATE TRIGGER #{trigger_name}
      AFTER INSERT OR DELETE
      ON #{prefix}.#{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE #{function_name}();"
  end

  def create_table_mutation_trigger_sql_UPDATE(
        table_name,
        prefix,
        trigger_name,
        function_name,
        nil
      ) do
    "CREATE TRIGGER #{trigger_name}
      AFTER UPDATE
      ON #{prefix}.#{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE #{function_name}();"
  end

  def create_table_mutation_trigger_sql_UPDATE(
        table_name,
        prefix,
        trigger_name,
        function_name,
        columns
      ) do
    "CREATE TRIGGER #{trigger_name}
      AFTER UPDATE OF #{columns}
      ON #{prefix}.#{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE #{function_name}();"
  end

  def delete_trigger(trigger_name, table_name, prefix) do
    Ecto.Migration.execute("DROP TRIGGER #{trigger_name} ON #{table_name}", prefix: "#{prefix}")
  end

  defmodule PayloadStrategy do
    def function_name, do: "broadcast_payload_changes"

    def get_trigger_name_INSERT_DELETE(table_name),
      do: "notify_#{table_name}_payload_INSERT_DELETE"

    def get_trigger_name_UPDATE(table_name), do: "notify_#{table_name}_payload_UPDATE"

    def create_postgres_broadcast_payload_function_sql(channel_to_broadcast_on) do
      "CREATE OR REPLACE FUNCTION #{function_name()}()
        RETURNS trigger AS $$
        DECLARE
          current_row RECORD;
        BEGIN
          IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            current_row := NEW;
          ELSE
            current_row := OLD;
          END IF;
          IF (TG_OP = 'INSERT') THEN
            OLD := NEW;
          END IF;
          IF (TG_OP = 'DELETE') THEN
            NEW := OLD;
          END IF;
        PERFORM pg_notify(
            '#{channel_to_broadcast_on}',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'schema', TG_TABLE_SCHEMA,
              'id', current_row.id,
              'new_row_data', row_to_json(NEW),
              'old_row_data', row_to_json(OLD)
            )::text
          );
        RETURN current_row;
        END;
        $$ LANGUAGE plpgsql;"
    end

    def broadcast_mutation_for_table(table_name, prefix, columns) do
      PostgrexPubsubMultiTenant.default_channel()
      |> create_postgres_broadcast_payload_function_sql()
      |> Ecto.Migration.execute(prefix: "#{prefix}")

      table_name
      |> PostgrexPubsubMultiTenant.create_table_mutation_trigger_sql_INSERT_DELETE(
        prefix,
        get_trigger_name_INSERT_DELETE(table_name),
        function_name()
      )
      |> Ecto.Migration.execute(prefix: "#{prefix}")

      table_name
      |> PostgrexPubsubMultiTenant.create_table_mutation_trigger_sql_UPDATE(
        prefix,
        get_trigger_name_UPDATE(table_name),
        function_name(),
        columns
      )
      |> Ecto.Migration.execute(prefix: "#{prefix}")
    end

    def delete_broadcast_trigger_for_table(table_name, prefix) do
      table_name
      |> get_trigger_name_INSERT_DELETE()
      |> PostgrexPubsubMultiTenant.delete_trigger(table_name, prefix)

      table_name
      |> get_trigger_name_UPDATE()
      |> PostgrexPubsubMultiTenant.delete_trigger(table_name, prefix)
    end
  end

  defmodule IdStrategy do
    def function_name, do: "broadcast_id_changes"
    def get_trigger_name_INSERT_DELETE(table_name), do: "notify_#{table_name}_id_INSERT_DELETE"
    def get_trigger_name_UPDATE(table_name), do: "notify_#{table_name}_id_UPDATE"

    def create_postgres_broadcast_id_function_sql(channel_to_broadcast_on) do
      "CREATE OR REPLACE FUNCTION #{function_name()}()
      RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;
        IF (TG_OP = 'INSERT') THEN
          OLD := NEW;
        END IF;
        IF (TG_OP = 'DELETE') THEN
          NEW := OLD;
        END IF;
      PERFORM pg_notify(
          '#{channel_to_broadcast_on}',
          json_build_object(
            'table', TG_TABLE_NAME,
            'type', TG_OP,
            'schema', TG_TABLE_SCHEMA,
            'id', current_row.id,
            'new_row_data', row_to_json(NEW),
            'old_row_data', row_to_json(OLD)
          )::text
        );
      RETURN current_row;
      END;
      $$ LANGUAGE plpgsql;"
    end

    def broadcast_mutation_for_table(table_name, prefix, columns) do
      PostgrexPubsubMultiTenant.default_channel()
      |> create_postgres_broadcast_id_function_sql()
      |> Ecto.Migration.execute(prefix: "#{prefix}")

      table_name
      |> PostgrexPubsubMultiTenant.create_table_mutation_trigger_sql_INSERT_DELETE(
        prefix,
        get_trigger_name_INSERT_DELETE(table_name),
        function_name()
      )
      |> Ecto.Migration.execute(prefix: "#{prefix}")

      table_name
      |> PostgrexPubsubMultiTenant.create_table_mutation_trigger_sql_UPDATE(
        prefix,
        get_trigger_name_UPDATE(table_name),
        function_name(),
        columns
      )
      |> Ecto.Migration.execute(prefix: "#{prefix}")
    end

    def delete_broadcast_trigger_for_table(table_name, prefix) do
      table_name
      |> get_trigger_name_INSERT_DELETE()
      |> PostgrexPubsubMultiTenant.delete_trigger(table_name, prefix)

      table_name
      |> get_trigger_name_UPDATE()
      |> PostgrexPubsubMultiTenant.delete_trigger(table_name, prefix)
    end
  end
end
