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
        statement = @conn
        |> apply(operation, [query])
        |> IO.iodata_to_binary

        fields = query
        |> Map.get(:select)
        |> Map.get(:fields)
        |> Enum.map(&field/1)

        request = %Request{
            statement: statement,
            fields: fields
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

    defp field({{_one, _two, [_three, name]}, _four, _five}) do
        name
    end
end