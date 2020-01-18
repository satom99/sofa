defmodule Sofa.Response do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
        field :status, :string
        field :signature, :map
        field :results, {:array, :map}

        embeds_one :metrics, Metrics do
            field :mutationCount, :integer
            field :resultCount, :integer
        end
        embeds_many :warnings, Warning do
            field :code, :integer
            field :msg, :string
        end
        embeds_many :errors, Error do
            field :code, :integer
            field :msg, :string
        end
    end

    def new(params) do
        %__MODULE__{}
        |> changeset(params)
        |> apply_changes
    end

    defp changeset(%schema{} = struct, %{} = params) do
        embeds = schema.__schema__(:embeds)
        fields = schema.__schema__(:fields)
        fields = fields -- embeds

        struct
        |> cast(params, fields)
        |> changeset(embeds)
    end
    defp changeset(struct, [embed | embeds]) do
       struct
       |> cast_embed(embed, with: &changeset/2)
       |> changeset(embeds)
    end
    defp changeset(struct, []) do
        struct
    end
end