defmodule Ecto.Adapters.Couchbase do
    @moduledoc false

    use Ecto.Adapters.SQL, [
        driver: :couchbase,
        migration_lock: nil
    ]

    import Sofa.Builder

    alias Ecto.Query
    alias Ecto.Query.SelectExpr
    alias Sofa.Request

    def supports_ddl_transaction? do
        false
    end

    def prepare(operation, query) do
        query = aliasing(query)
        signature = signature(query)

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

    defp aliasing(%Query{select: nil} = query) do
        query
    end
    defp aliasing(%Query{select: select} = query) do
        select = aliasing(select)
        %{query | select: select}
    end
    defp aliasing(%SelectExpr{fields: fields} = select) do
        fields = aliasing(fields)
        %{select | fields: fields}
    end
    defp aliasing(expressions) when is_list(expressions) do
        expressions
        |> Enum.map(&aliasing/1)
        |> Enum.reduce({[], []}, &aliasing/2)
        |> Kernel.elem(1)
        |> Enum.reverse
    end
    defp aliasing({:fragment, _context, _options} = expression) do
        {reference(), expression}
    end
    defp aliasing(expression) do
        expression
    end
    defp aliasing(expression, {uniques, expressions}) do
        unique = uniqueness(expression)
        expression = unless unique in uniques do
            expression
        else
            {reference(), expression}
        end
        {[unique | uniques], [expression | expressions]}
    end

    defp signature(%Query{select: nil}) do
        []
    end
    defp signature(%Query{select: select}) do
        select
        |> Map.get(:fields)
        |> Enum.map(&signature/1)
        |> Enum.map(&to_string/1)
    end
    defp signature({alias, _expression}) do
        alias
    end
    defp signature(expression) do
        uniqueness(expression)
    end

    defp uniqueness({tuple, _context, _arguments}) when is_tuple(tuple) do
        uniqueness(tuple)
    end
    defp uniqueness({:., _context, arguments}) do
        List.last(arguments)
    end
    defp uniqueness(expression) do
        expression
    end
end