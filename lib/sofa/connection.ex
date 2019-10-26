defmodule Ecto.Adapters.Couchbase.Connection do
    @moduledoc false

    @behaviour Ecto.Adapters.SQL.Connection

    alias Ecto.Adapters.MyXQL.Connection
    alias Sofa.Query

    def child_spec(options) do
        IO.inspect {:child_spec, options}
        Sofa.child_spec(options)
    end

    def prepare_execute(conn, _name, statement, params, options) do
        query = %Query{statement: statement}
        DBConnection.prepare_execute(conn, query, params, options)
    end
    def execute(conn, query, params, options) do
        DBConnection.execute(conn, query, params, options)
    end
    def query(conn, statement, params, options) do
        statement = IO.iodata_to_binary(statement)
        execution = prepare_execute(conn, nil, statement, params, options)
        result(execution)
    end

    def stream(_conn, _statement, _params, _options) do
        raise "not implemented"
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
    def insert(_prefix, _table, _header, _rows, _conflict, _returning) do
        raise "not implemented"
    end

    def to_constraints(_term) do
        []
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

    defp result({:ok, _query, result}) do
        {:ok, result}
    end
    defp result({:error, _reason} = tuple) do
        tuple
    end
end