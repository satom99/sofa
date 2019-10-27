defmodule Sofa.Filter do
    @moduledoc """
    Work in progress.
    """
    alias Ecto.Changeset
    alias Ecto.Query.DynamicExpr
    alias Sofa.Filter.Validator
    alias Sofa.Filter.Builder
    alias __MODULE__

    defstruct [
        :op,
        :value,
        :apply,
        path: ""
    ]
    
    @typedoc """
    Internal representation of a filter.
    """
    @type t :: %Filter{
        op: operation,
        path: String.t,
        value: term,
        apply: [t]
    }

    @typedoc """
    List of implemented operations.
    """
    @type operation :: :defined
        | :less | :more
        | :test | :matches | :contains
        | :starts | :ends | :test
        | :any | :and | :or

    @doc """
    Builds a dynamic expression from a given `t:t/0` struct.
    """
    @spec build(t) :: DynamicExpr.t

    def build(struct) do
        Builder.build(struct)
    end

    @doc """
    Attempts to cast a `t:t/0` struct from a given map.
    """
    @spec cast(map) :: {:ok, t} | {:error, Changeset.t}

    def cast(object) do
        Validator.cast(object)
    end
end