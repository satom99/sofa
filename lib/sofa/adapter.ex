defmodule Ecto.Adapters.Couchbase do
    @moduledoc false

    use Ecto.Adapters.SQL, [
        driver: :couchbase,
        migration_lock: nil
    ]

    def supports_ddl_transaction? do
        false
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
end