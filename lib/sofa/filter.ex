defmodule Sofa.Filter do
    @moduledoc """
    Work in progress.
    """
    import Kernel, except: [apply: 2]

    alias Ecto.Query
    alias Ecto.Changeset
    alias Ecto.Queryable
    alias Sofa.Filter.Validator
    alias Sofa.Filter.Builder
    alias __MODULE__

    defstruct [
        :op,
        :value,
        :apply,
        :path
    ]

    @typedoc """
    Internal representation.
    """
    @type t :: %Filter{
        op: operation,
        path: [String.t],
        value: term,
        apply: [t]
    }

    @typedoc """
    Implemented operations.
    """
    @type operation :: :defined
        | :less | :more
        | :test | :matches | :contains
        | :starts | :ends | :test
        | :any | :and | :or

    @doc """
    Casts a `t:t/0` struct from a given map.
    """
    @spec cast(map) :: {:ok, t} | {:error, Changeset.t}

    def cast(object) do
        Validator.cast(object)
    end
    
    @doc """
    Applies a given filter to a query.
    """
    def apply(%Query{} = query, %Filter{} = filter) do
        Builder.apply(query, filter)
    end
    def apply(queryable, %Filter{} = filter) do
        queryable
        |> Queryable.to_query
        |> apply(filter)
    end
end