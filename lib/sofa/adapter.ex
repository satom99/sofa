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
        primary = Keyword.take(params, [:id])
        params = Enum.concat(primary, params)
        super(adapter, schema, params, conflict, returning, options)
    end
end