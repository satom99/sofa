defmodule Sofa do
    @moduledoc false

    alias Sofa.{Query, Worker}

    def start_link(options) do
        DBConnection.start_link(Worker, options)
    end

    def child_spec(options) do
        DBConnection.child_spec(Worker, options)
    end

    def prepare_execute(conn, _name, query, params, options) do
        DBConnection.prepare_execute(conn, query, params, options)
    end

    def execute(conn, query, params, options) do
        DBConnection.execute(conn, query, params, options)
    end

    def query(conn, %Query{} = query, params, options) do
        conn
        |> prepare_execute(nil, query, params, options)
        |> result
    end
    def query(conn, statement, params, options) do
        statement = IO.iodata_to_binary(statement)
        query = %Query{statement: statement}
        query(conn, query, params, options)
    end
    
    def stream(_conn, _query, _params, _options) do
        raise "not implemented"
    end

    defp result({:ok, _query, result}) do
        {:ok, result}
    end
    defp result({:error, _reason} = tuple) do
        tuple
    end
end