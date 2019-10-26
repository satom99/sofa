defmodule Sofa do
	@moduledoc false

	alias Sofa.Worker

	def start_link(options) do
		DBConnection.start_link(Worker, options)
	end
	def child_spec(options) do
		DBConnection.child_spec(Worker, options)
	end
end