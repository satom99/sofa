defmodule Sofa do
    @moduledoc false

    alias Sofa.{Request, Worker}

    def start_link(options) do
        DBConnection.start_link(Worker, options)
    end

    def child_spec(options) do
        DBConnection.child_spec(Worker, options)
    end

    def prepare_execute(conn, _name, request, params, options) do
        DBConnection.prepare_execute(conn, request, params, options)
    end

    def execute(conn, request, params, options) do
        DBConnection.execute(conn, request, params, options)
    end

    def query(conn, %Request{} = request, params, options) do
        conn
        |> prepare_execute(nil, request, params, options)
        |> result
    end
    def query(conn, statement, params, options) do
        statement = IO.iodata_to_binary(statement)
        request = %Request{statement: statement}
        query(conn, request, params, options)
    end
    
    def stream(_conn, _request, _params, _options) do
        raise "not implemented"
    end

    defp result({:ok, _request, result}) do
        {:ok, result}
    end
    defp result({:error, _reason} = tuple) do
        tuple
    end
end