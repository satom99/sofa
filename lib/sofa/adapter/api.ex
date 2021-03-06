defmodule Sofa.API do
    @moduledoc false

    use HTTPoison.Base

    alias Sofa.Response

    def execute(statement, params, options) do
        payload = %{
            args: params,
            statement: statement
        }
        url = format_url(options)
        post(url, payload, [], options)
    end

    def process_request_body(body) do
        Jason.encode!(body)
    end

    def process_request_headers(headers) do
        [
            {"Content-Type", "application/json"}
            | headers
        ]
    end

    def process_request_options(options) do
        username = Keyword.fetch!(options, :username)
        password = Keyword.fetch!(options, :password)
        hackney = [basic_auth: {username, password}]
        timeout = {:recv_timeout, options[:timeout]}
        [{:hackney, hackney}, timeout | options]
    end

    def process_response_body(body) do
        body
        |> Jason.decode!
        |> Response.new
    end

    defp format_url(options) do
        host = Keyword.fetch!(options, :hostname)
        "http://#{host}:8093/query/service"
    end
end