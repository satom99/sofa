defmodule Sofa.MixProject do
	use Mix.Project

	def project do
		[
			app: :sofa,
			version: "0.1.0",
			elixir: "~> 1.2",
			build_embedded: Mix.env == :prod,
			deps: deps()
		]
	end

	defp deps do
		[
			{:ecto, ">= 3.1.0"},
			{:myxql, ">= 0.2.0"},
			{:jason, ">= 1.0.0"},
			{:ecto_sql, ">= 3.1.0"},
			{:httpoison, ">= 0.7.0"},
			{:db_connection, ">= 0.1.0"},
			{:ex_doc, ">= 0.5.1", only: :dev}
		]
	end
end