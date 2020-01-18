defmodule Sofa.Worker do
    @moduledoc false

    use DBConnection

    alias Sofa.{Request, Result}
    alias Sofa.{API, Response}

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

    def handle_prepare(request, _options, state) do
        {:ok, request, state}
    end
    def handle_execute(%Request{statement: statement} = request, params, _options, state) do
        statement
        |> API.execute(params, state)
        |> result(request, state)
    end

    def handle_close(_request, _options, state) do
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
    def handle_declare(_request, _params, _options, _state) do
        raise "not implemented"
    end
    def handle_fetch(_request, _cursor, _options, _state) do
        raise "not implemented"
    end
    def handle_deallocate(_request, _cursor, _options, _state) do
        raise "not implemented"
    end

    defp result({_code, struct}, request, state) do
        result(struct, request, state)
    end
    defp result(%{body: body}, request, state) do
        result(body, request, state)
    end
    defp result(%Response{signature: nil, metrics: metrics}, request, state) do
        count = Map.get(metrics, :mutationCount, 1)
        result = %Result{num_rows: count}
        {:ok, request, result, state}
    end
    defp result(%Response{signature: signature} = response, %Request{signature: nil} = request, state) do
        signature = Map.keys(signature)
        request = %{request | signature: signature}
        result(response, request, state)
    end
    defp result(%Response{results: results}, %Request{signature: signature} = request, state) do
        result = %Result{
            num_rows: length(results),
            rows: values(results, signature),
            columns: signature
        }
        {:ok, request, result, state}
    end
    defp result(error, _request, state) do
        message = format_error(error)
        {:error, message, state}
    end

    defp values(results, signature) when is_list(results) do
        Enum.map(results, &values(&1, signature))
    end
    defp values(object, signature) do
        Enum.map(signature, &Map.get(object, &1))
    end

    defp format_error(%Response{errors: errors}) do
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
    defp format_error(object) do
        inspect(object)
    end
end