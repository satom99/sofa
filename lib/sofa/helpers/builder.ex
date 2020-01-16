defmodule Sofa.Builder do
    @moduledoc false

    alias Ecto.Query
    alias Ecto.Query.DynamicExpr
    alias Ecto.Query.Builder.Dynamic
    alias __MODULE__

    @boundaries ~r/%{([a-z]*)}/
    @starter {0, ""}

    @doc """
    Scopes root paths for a specific a query.
    """
    @spec names(struct, Query.t) :: struct

    def names(predicates, query) when is_list(predicates) do
        Enum.map(predicates, &names(&1, query))
    end
    def names(%{path: nil, apply: apply} = predicate, query) do
        apply = names(apply, query)
        %{predicate | apply: apply}
    end
    def names(%{path: [source | rest]} = predicate, %Query{aliases: aliases}) do
        source = handle(aliases, source)
        finale = [source | rest]
        %{predicate | path: finale}
    end

    @doc """
    Scopes child paths from a given parent.
    """
    @spec scoped(struct, struct) :: struct
    
    def scoped(predicate, %{path: nil}) do
        predicate
    end
    def scoped(%{path: nil} = predicate, %{path: path}) do
        %{predicate | path: path}
    end
    def scoped(%{path: path} = predicate, %{path: parent}) do
        %{predicate | path: parent ++ path}
    end

    @doc """
    Generates a unique reference to be used as an alias.
    """
    @spec reference :: String.t
    
    def reference do
        make_ref()
        |> :erlang.ref_to_list
        |> to_string
    end

    @doc """
    Injects raw variables within a fragment.
    """
    @spec dynamo(term, term) :: DynamicExpr.t

    defmacro dynamo(binding, fragment) do
        binding = binding
        |> Map.new
        |> zipper
        
        []
        |> Dynamic.build(fragment, __CALLER__)
        |> Macro.postwalk(&binder(&1, binding))
    end

    @doc """
    Escapes a given path at runtime.
    """
    @spec escape(term) :: String.t

    def escape(parts) when is_list(parts) do
        parts
        |> List.flatten
        |> Enum.map(&escape/1)
        |> Enum.intersperse(".")
        |> Enum.reduce("", &escape/2)
        |> fragmentize
    end
    def escape(object) when not is_binary(object) do
        object
    end
    def escape(string) when byte_size(string) > 0 do
        "`#{string}`"
    end
    defp escape(object, previous) do
        concat(previous, object)
    end

    defp binder({:raw, statement}, binding) when byte_size(statement) > 0 do
        {caret, tree} = @boundaries
        |> Regex.scan(statement, return: :index)
        |> Enum.reduce(@starter, &binder(&1, statement, binding, &2))

        length = byte_size(statement)
        offset = length - caret
        ending = binary_part(statement, caret, offset)

        tree = tree
        |> concat(ending)
        |> fragmentize
        |> escape_once

        {:expr, tree}
    end
    defp binder(object, _binding) do
        object
    end
    defp binder([match, capture], statement, binding, {caret, tree}) do
        {start, length} = match
        offset = start - caret
        before = binary_part(statement, caret, offset)
        caret = start + length

        {start, length} = capture
        name = binary_part(statement, start, length)
        bind = Map.fetch!(binding, name)

        tree = tree
        |> concat(before)
        |> concat(bind)
        |> fragmentize
        |> escape_once

        {caret, tree}
    end

    defp concat(previous, object) when not is_list(previous) do
        []
        |> concat(previous)
        |> concat(object)
    end
    defp concat(previous, {:path, _context, _arguments} = path) do
        object = quote do
            path = unquote(path)
            Builder.escape(path)
        end
        concat(previous, object)
    end
    defp concat(previous, {:alias, _context, _arguments} = alias) do
        object = quote do
            alias = unquote(alias)
            Builder.escape(alias)
        end
        previous ++ [raw: object]
    end
    defp concat(previous, object) when not is_binary(object) do
        previous ++ [expr: object]
    end
    defp concat(previous, object) when byte_size(object) > 0 do
        previous ++ [raw: object]
    end
    defp concat(previous, _object) do
        previous
    end
    
    defp fragmentize(parts) do
        {:fragment, [], parts}
    end
    defp escape_once(execution) do
        execution = Tuple.to_list(execution)
        {:{}, [], execution}
    end

    defp handle(%{} = aliases, source) do
        aliases
        |> zipper
        |> Map.get(source)
        |> handle(source)
    end
    defp handle(nil, source) do
        root = handle(0, source)
        [root, source]
    end
    defp handle(index, _source) do
        {:&, [], [index]}
    end

    defp zipper(list) when is_list(list) do
        Enum.map(list, &zipper/1)
    end
    defp zipper(%{} = object) do
        Map.new(object, &zipper/1)
    end
    defp zipper({name, value}) do
        name = to_string(name)
        {name, value}
    end
end