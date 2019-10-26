defmodule Ecto.Adapters.Couchbase do
    @moduledoc false

    use Ecto.Adapters.SQL, [
        driver: :couchbase,
        migration_lock: nil
    ]

    def supports_ddl_transaction? do
        false
    end
end