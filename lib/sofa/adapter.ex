defmodule Ecto.Adapters.Couchbase do
    @moduledoc false

    use Ecto.Adapters.SQL, [
        driver: :couchbase,
        migration_lock: nil
    ]
    alias Sofa.Request

    def supports_ddl_transaction? do
        false
    end

    def prepare(operation, query) do
        signature = query
        |> Map.get(:select)
        |> Map.get(:fields)
        |> Enum.map(&field/1)

        fields = query
        |> Map.get(:select)
        |> Map.get(:fields)
        |> Enum.uniq_by(&uniqueness/1)

        select = query
        |> Map.get(:select)
        |> Map.put(:fields, fields)

        query = query
        |> Map.put(:select, select)
        |> Map.put(:tampered, true)

        statement = @conn
        |> apply(operation, [query])
        |> IO.iodata_to_binary

        request = %Request{
            statement: statement,
            signature: signature
        }
        {:cache, {System.unique_integer([:positive]), request}}
    end

    def insert(adapter, schema, params, conflict, returning, options) do
        params = primarize(params)
        super(adapter, schema, params, conflict, returning, options)
    end
    def insert_all(adapter, schema, header, params, conflict, returning, options) do
        header = [:id | header]
        params = Enum.map(params, &primarize/1)
        super(adapter, schema, header, params, conflict, returning, options)
    end

    defp primarize(params) do
        params
        |> Keyword.take([:id])
        |> Enum.concat(params)
    end

    defp field(expression) do
        expression
        |> expand
        |> List.last
    end
    
    defp uniqueness(expression) do
        expand(expression)
    end

    defp expand({:., _context, arguments}) do
        arguments
    end
    defp expand({tuple, _context, _arguments}) do
        expand(tuple)
    end
end