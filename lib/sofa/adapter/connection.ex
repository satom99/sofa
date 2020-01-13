defmodule Ecto.Adapters.Couchbase.Connection do
    @moduledoc false

    @behaviour Ecto.Adapters.SQL.Connection

    alias Ecto.Adapters.MyXQL.Connection

    def child_spec(options) do
        Sofa.child_spec(options)
    end

    def prepare_execute(conn, name, query, params, options) do
        Sofa.prepare_execute(conn, name, query, params, options)
    end

    def execute(conn, query, params, options) do
        Sofa.execute(conn, query, params, options)
    end

    def query(conn, query, params, options) do
        Sofa.query(conn, query, params, options)
    end

    def stream(conn, query, params, options) do
        Sofa.stream(conn, query, params, options)
    end

    def to_constraints(_error) do
        []
    end

    def all(query) do
        Connection.all(query)
    end
    def update_all(query) do
        Connection.update_all(query)
    end
    def delete_all(query) do
        Connection.delete_all(query)
    end

    def update(prefix, table, fields, filters, returning) do
        Connection.update(prefix, table, fields, filters, returning)
    end
    def delete(prefix, table, filters, returning) do
        Connection.delete(prefix, table, filters, returning)
    end
    def insert(prefix, table, header, rows, _conflict, _returning) do
        length = length(rows)
        source = quote_table(prefix, table)
        values = values(header, length)
        ["UPSERT INTO ", source, " (KEY, VALUE) ", "VALUES ", values]
    end

    def ddl_logs(_term) do
        raise "not implemented"
    end
    def execute_ddl(_tuple) do
        raise "not implemented"
    end
    def table_exists_query(_table) do
        raise "not implemented"
    end

    defp values(header, count) do
        object = header
        |> Enum.drop(1)
        |> Enum.map(&{&1, "?"})
        |> Map.new
        |> Jason.encode!
        |> String.replace("\"?\"", "?")

        [?(, ??, ?,, object, ?)]
        |> List.duplicate(count)
        |> Enum.intersperse(?,)
    end

    defp quote_table(nil, name) do
        quote_table(name)
    end
    defp quote_table(prefix, name) do
        [quote_table(prefix), ?., quote_table(name)]
    end
    defp quote_table(name) do
        [?`, to_string(name), ?`]
    end
end