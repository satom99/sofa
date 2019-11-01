defmodule Sofa.Filter.Validator do
    @moduledoc false

    import Ecto.Changeset

    alias Sofa.Filter

    @base %Filter{}
    @types %{op: :string, path: :string}
    @fields Map.keys(@types)

    def cast(object) do
        case validate(object) do
            %{valid?: true} = changeset ->
                filter = apply_changes(changeset)
                {:ok, filter}
            changeset ->
                {:error, changeset}
        end
    end

    defp validate(object) do
        {@base, @types}
        |> cast(object, @fields)
        |> validate_required([:op])
        |> validate_operation(object)
        |> transform
    end

    defp validate_operation(changeset, object) do
        changeset
        |> get_change(:op)
        |> operate(changeset, object)
    end
    defp operate("defined", changeset, _object) do
        changeset
    end
    defp operate("less", changeset, object) do
        insert(changeset, object)
    end
    defp operate("more", changeset, object) do
        insert(changeset, object)
    end
    defp operate("matches", changeset, object) do
        update(changeset, :string, object)
    end
    defp operate("contains", changeset, object) do
        update(changeset, :string, object)
    end
    defp operate("starts", changeset, object) do
        update(changeset, :string, object)
    end
    defp operate("ends", changeset, object) do
        update(changeset, :string, object)
    end
    defp operate("test", changeset, object) do
        insert(changeset, object)
    end
    defp operate("and", changeset, object) do
        reduce(changeset, {:array, :map}, object)
    end
    defp operate("or", changeset, object) do
        reduce(changeset, {:array, :map}, object)
    end
    defp operate("any", changeset, object) do
        reduce(changeset, :map, object)
    end
    defp operate(_code, changeset, _object) do
        add_error(changeset, :op, "unknown")
    end

    defp insert(changeset, object) do
        input = Map.get(object, "value")

        changes = changeset
        |> Map.get(:changes)
        |> Map.put(:value, input)

        types = changeset
        |> Map.get(:types)
        |> Map.put(:value, :term)

        changeset
        |> Map.put(:types, types)
        |> Map.put(:changes, changes)
        |> validate_required([:value])
    end
    defp update(changeset, type, object) do
        types = changeset
        |> Map.get(:types)
        |> Map.put(:value, type)

        changeset
        |> Map.put(:types, types)
        |> cast(object, [:value])
        |> validate_required([:value])
    end
    defp reduce(changeset, type, object) do
        types = changeset
        |> Map.get(:types)
        |> Map.put(:apply, type)

        changeset = changeset
        |> Map.put(:types, types)
        |> cast(object, [:apply])
        |> validate_required([:apply])

        if changeset.valid? do
            children = changeset
            |> get_change(:apply)
            |> List.wrap
            |> Enum.map(&validate/1)

            errors = children
            |> Enum.map(& &1.errors)
            |> List.flatten

            count = length(errors)

            children = Enum.map(children, &apply_changes/1)

            changes = changeset
            |> Map.get(:changes)
            |> Map.put(:apply, children)

            changeset
            |> Map.put(:errors, errors)
            |> Map.put(:valid?, count < 1)
            |> Map.put(:changes, changes)
        else
            changeset
        end
    end

    defp transform(%{valid?: true} = changeset) do
        code = changeset
        |> get_change(:op)
        |> String.to_atom

        path = changeset
        |> get_change(:path, "")
        |> String.replace("/", ".")
        |> String.split(".")
        |> Enum.map(&"`#{&1}`")
        |> Enum.join(".")

        changes = changeset
        |> Map.get(:changes)
        |> Map.put(:op, code)
        |> Map.put(:path, path)

        Map.put(changeset, :changes, changes)
    end
    defp transform(changeset) do
        changeset
    end
end