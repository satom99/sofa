defmodule Sofa.Filter.Builder do
    @moduledoc false

    import Ecto.Query

    alias Ecto.Query.Builder.Dynamic
    alias Sofa.Filter

    @boundaries ~r/%{([a-z]*)}/

    def build(nil) do
        []
    end
    def build(%Filter{} = filter) do
        process(filter)
    end

    defmacrop dynamo(binding, fragment) do
        values = Keyword.values(binding)

        binding = binding
        |> Keyword.keys
        |> Enum.map(&to_string/1)
        |> Enum.zip(values)
        |> Map.new

        []
        |> Dynamic.build(fragment, __CALLER__)
        |> Macro.postwalk(&binder(&1, binding))
    end

    defp binder({:raw, ""} = tuple, _binding) do
        tuple
    end
    defp binder({:raw, statement}, binding) do
        {caret, tree} = @boundaries
        |> Regex.scan(statement, return: :index)
        |> Enum.reduce({0, ""}, &reduce(&1, &2, statement, binding))

        length = byte_size(statement)
        offset = length - caret
        finale = binary_part(statement, caret, offset)

        tree = []
        |> insert(tree)
        |> insert(finale)
        |> fragmentize

        {:expr, tree}
    end
    defp binder(term, _binding) do
        term
    end

    defp reduce([match, capture], {caret, tree}, statement, binding) do
        {start, length} = match
        offset = start - caret
        before = binary_part(statement, caret, offset)
        caret = start + length

        {start, length} = capture
        name = binary_part(statement, start, length)
        param = Map.fetch!(binding, name)

        root = quote do &0 end
        root = Macro.escape(root)

        scoped = param
        |> scope(root)
        |> fragmentize

        tree = []
        |> insert(tree)
        |> insert(before)
        |> insert(scoped)
        |> fragmentize

        {caret, tree}
    end

    defp insert(parts, kind, item) do
        parts ++ [{kind, item}]
    end
    defp insert(parts, item) when not is_binary(item) do
        insert(parts, :expr, item)
    end
    defp insert(parts, item) when byte_size(item) > 0 do
        insert(parts, :raw, item)
    end
    defp insert(parts, _item) do
        parts
    end
    defp scope({:path, _meta, _arguments} = param, root) do
        quote do
            root = unquote(root)
            param = unquote(param)
            param = List.wrap(param)
            first = List.first(param)

            if first == :scoped do
                param = param
                |> Enum.drop(1)
                |> Enum.join(".")

                [raw: param]
            else
                param = Enum.join(param, ".")
                []
                |> insert(root)
                |> insert(".")
                |> insert(:raw, param)
            end
        end
    end
    defp scope(param, _root) do
        [raw: param]
    end
    defp fragmentize(parts) do
        {:{}, [], [:fragment, [], parts]}
    end

    defp update_path(%Filter{path: path} = filter, %Filter{path: ""}) do
        filter
    end
    defp update_path(%Filter{path: ""} = filter, %Filter{path: parent}) do
        %{filter | path: parent}
    end
    defp update_path(%Filter{path: path} = filter, %Filter{path: parent}) do
        parent = List.wrap(parent)
        finale = parent ++ [path]
        %{filter | path: finale}
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
    defp process(%Filter{op: :and, apply: [object | list]} = parent) do
        parent = %{parent | apply: list}
        object = update_path(object, parent)
        dynamic ^process(object) and ^process(parent)
    end
    defp process(%Filter{op: :and, apply: []}) do
        dynamic fragment("true")
    end
    defp process(%Filter{op: :or, apply: [object | list]} = parent) do
        parent = %{parent | apply: list}
        object = update_path(object, parent)
        dynamic ^process(object) or ^process(parent)
    end
    defp process(%Filter{op: :or, apply: []}) do
        dynamic fragment("false")
    end
    defp process(%Filter{op: :any, path: path, apply: [object]} = parent) do
        reference = make_ref()
        |> :erlang.ref_to_list
        |> to_string

        escape = "`#{reference}`"
        scoped = [:scoped, escape]
        parent = %{parent | path: scoped}
        object = update_path(object, parent)

        dynamo [path: path, alias: escape], fragment(
            "ANY %{alias} IN %{path} SATISFIES ? END",
            ^process(object)
        )
    end
end