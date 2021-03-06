defmodule Sofa.Schema do
    @moduledoc """
    Work in progress.
    """
    alias Ecto.Queryable

    @doc """
    Function used to determine a source at run-time.

    Must be defined after the schema macro call.
    """
    @callback __source__ :: term

    @doc """
    Function used to filter a queryable.
    """
    @callback filter(Queryable.t, Enumerable.t) :: Queryable.t

    @optional_callbacks [__source__: 0, filter: 2]

    defmacro __using__(_options) do
        quote do
            use Ecto.Schema

            import Ecto.Query
            import Sofa.Query

            alias Sofa.Filter

            @behaviour Sofa.Schema
            @on_definition {Sofa.Schema, :definition}
            @derive {Jason.Encoder, except: [:__meta__]}
            @primary_key {:id, :string, []}
            @foreign_key_type :string

            def filter(object, params) do
                fields = __schema__(:fields)

                filter = params
                |> Map.new
                |> Map.get(:filter)

                clauses = params
                |> Map.new
                |> Map.take(fields)
                |> Keyword.new

                object
                |> where(^clauses)
                |> Filter.apply(filter)
            end
            defoverridable [filter: 2]
        end
    end

    @doc false
    def definition(%{module: module}, _kind, :__source__, [], _guards, _body) do
        override = quote do
            defoverridable [__schema__: 1, __struct__: 0, __struct__: 1]

            def __schema__(:source) do
                __source__()
            end
            def __schema__(:query) do
                query = super(:query)
                source = __schema__(:source)
                source = {source, __MODULE__}

                from = query
                |> Map.get(:from)
                |> Map.put(:source, source)

                %{query | from: from}
            end
            def __schema__(value) do
                super(value)
            end

            def __struct__(fields) do
                struct = super(fields)
                source = __schema__(:source)

                metadata = struct
                |> Map.get(:__meta__)
                |> Map.put(:source, source)

                %{struct | __meta__: metadata}
            end
            def __struct__ do
                __struct__([])
            end
        end
        Module.eval_quoted(module, override)
    end
    def definition(_environment, _kind, _name, _args, _guards, _body) do
        :noop
    end
end