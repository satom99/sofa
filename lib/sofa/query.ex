defmodule Sofa.Query do
    @moduledoc false

    alias Ecto.Query
    alias Ecto.Query.JoinExpr

    defmacro nest(query, qualifier, binding \\ [], expression, options \\ []) do
        quote do
            query = Query.join(
                unquote(query),
                unquote(qualifier),
                unquote(binding),
                unquote(expression),
                unquote(options)
            )
            Sofa.Query.nested(query)
        end
    end

    def nested(%Query{} = query) do
        Map.update!(query, :joins, &nested/1)
    end
    def nested(joins) when is_list(joins) do
        [join | rest] = Enum.reverse(joins)
        nested = nested(join)
        finale = [nested | rest]
        Enum.reverse(finale)
    end
    def nested(%JoinExpr{} = expression) do
        Map.put(expression, :qual, :nest)
    end
end