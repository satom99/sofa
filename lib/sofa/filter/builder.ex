defmodule Sofa.Filter.Builder do
    @moduledoc false

    import Ecto.Query
    import Sofa.Builder

    alias Ecto.Query
    alias Sofa.Filter

    def apply(%Query{} = query, %Filter{} = filter) do
        clauses = filter
        |> names(query)
        |> process

        where(query, ^clauses)
    end

    defp process(%Filter{op: :defined, path: path}) do
        dynamo [path: path], fragment(
            "%{path} IS NOT MISSING"
        )
    end
    defp process(%Filter{op: :less, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} < ?",
            ^value
        )
    end
    defp process(%Filter{op: :more, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} > ?",
            ^value
        )
    end
    defp process(%Filter{op: :matches, path: path, value: value}) do
        dynamo [path: path], fragment(
            "REGEXP_LIKE(%{path}, ?)",
            ^value
        )
    end
    defp process(%Filter{op: :contains, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} LIKE ?",
            ^"%#{value}%"
        )
    end
    defp process(%Filter{op: :starts, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} LIKE ?",
            ^"#{value}%"
        )
    end
    defp process(%Filter{op: :ends, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} LIKE ?",
            ^"%#{value}"
        )
    end
    defp process(%Filter{op: :test, path: path, value: value}) do
        dynamo [path: path], fragment(
            "%{path} = ?",
            ^value
        )
    end
    defp process(%Filter{op: :and, apply: [filter | rest]} = parent) do
        parent = %{parent | apply: rest}
        filter = scoped(filter, parent)
        dynamic ^process(filter) and ^process(parent)
    end
    defp process(%Filter{op: :and, apply: []}) do
        dynamic fragment("true")
    end
    defp process(%Filter{op: :or, apply: [filter | rest]} = parent) do
        parent = %{parent | apply: rest}
        filter = scoped(filter, parent)
        dynamic ^process(filter) or ^process(parent)
    end
    defp process(%Filter{op: :or, apply: []}) do
        dynamic fragment("false")
    end
    defp process(%Filter{op: :any, path: path, apply: [filter]} = parent) do
        alias = reference()
        scoped = [alias]
        parent = %{parent | path: scoped}
        filter = scoped(filter, parent)

        dynamo [path: path, alias: alias], fragment(
            "ANY %{alias} IN %{path} SATISFIES ? END",
            ^process(filter)
        )
    end
end