defmodule Sofa.Worker do
    @moduledoc false

    use DBConnection

    alias Sofa.{Query, Result}
    alias Sofa.API

    def connect(options) do
        {:ok, options}
    end

    def disconnect(_reason, _state) do
        :ok
    end

    def checkout(state) do
        {:ok, state}
    end

    def checkin(state) do
        {:ok, state}
    end

    def ping(state) do
        {:ok, state}
    end

    def handle_prepare(query, _options, state) do
        {:ok, query, state}
    end
    def handle_execute(%Query{statement: statement} = query, params, _options, state) do
        statement
        |> API.execute(params, state)
        |> result(query, state)
    end

    def handle_close(_query, _options, state) do
        {:ok, nil, state}
    end

    def handle_begin(_options, _state) do
        raise "not implemented"
    end
    def handle_commit(_options, _state) do
        raise "not implemented"
    end
    def handle_rollback(_options, _state) do
        raise "not implemented"
    end
    def handle_status(_options, _state) do
        raise "not implemented"
    end
    def handle_declare(_query, _params, _options, _state) do
        raise "not implemented"
    end
    def handle_fetch(_query, _cursor, _options, _state) do
        raise "not implemented"
    end
    def handle_deallocate(_query, _cursor, _options, _state) do
        raise "not implemented"
    end

    defp result({_code, term}, query, state) do
        result(term, query, state)
    end
    defp result(%{body: body}, query, state) do
        result(body, query, state)
    end
    defp result(%{signature: nil, metrics: metrics}, query, state) do
        %{mutationCount: count} = metrics
        result = %Result{num_rows: count}
        {:ok, query, result, state}
    end
    defp result(%{signature: signature, results: results}, query, state) do
        fields = Map.keys(signature)
        values = Enum.map(results, &values(&1, fields))
        result = %Result{
            num_rows: length(values),
            columns: fields,
            rows: values
        }
        {:ok, query, result, state}
    end
    defp result(error, _query, state) do
        message = format_error(error)
        {:error, message, state}
    end

    defp values(object, fields) do
        Enum.map(fields, &Map.get(object, &1))
    end

    defp format_error(%{errors: errors}) do
        errors
        |> Enum.map(&format_error/1)
        |> Enum.join("\n")
    end
    defp format_error(%{code: code, msg: message}) do
        "(#{code}) #{message}"
    end
    defp format_error(%{reason: reason}) do
        format_error(reason)
    end
    defp format_error(term) do
        inspect(term)
    end
end