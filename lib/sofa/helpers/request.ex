defmodule Sofa.Request do
    @moduledoc false

    defstruct [
        :statement,
        :signature
    ]

    defimpl String.Chars do
        def to_string(%{statement: statement}) do
            IO.iodata_to_binary(statement)
        end
    end

    defimpl DBConnection.Query do
        def parse(query, _options) do
            query
        end
        def describe(query, _options) do
            query
        end
        def encode(_query, params, _options) do
            params
        end
        def decode(_query, result, _options) do
            result
        end
    end
end