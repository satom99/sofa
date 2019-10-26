defmodule Sofa.API do
    @moduledoc false

    use HTTPoison.Base

    def execute(statement, params, options) do
        payload = %{
            args: params,
            statement: statement
        }
        url = format_url(options)
        post(url, payload, [], options)
    end

    def format_url(options) do
        host = Keyword.fetch!(options, :hostname)
        "http://#{host}:8093/query/service"
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
        [{:hackney, hackney} | options]
    end

    def process_response_body(body) do
        Jason.decode!(body, keys: :atoms)
    end
end