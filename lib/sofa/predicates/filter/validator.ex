defmodule Sofa.Filter.Validator do
    @moduledoc false

    import Ecto.Changeset

    alias Sofa.Filter

    @base %Filter{}
    @apply {:array, :map}
    @types %{op: :string, path: :string}
    @fields Map.keys(@types)

    def cast(object) do
        case process(object) do
            %{valid?: true} = changeset ->
                filter = apply_changes(changeset)
                {:ok, filter}
            changeset ->
                {:error, changeset}
        end
    end

    defp process(object) do
        {@base, @types}
        |> cast(object, @fields)
        |> validate_required(:op)
        |> validate_operation
        |> transform
    end

    defp validate_operation(changeset) do
        changeset
        |> get_change(:op)
        |> operate(changeset)
    end
    defp operate("defined", changeset) do
        changeset
    end
    defp operate("less", changeset) do
        insert(changeset)
    end
    defp operate("more", changeset) do
        insert(changeset)
    end
    defp operate("matches", changeset) do
        update(changeset, :string)
    end
    defp operate("contains", changeset) do
        update(changeset, :string)
    end
    defp operate("starts", changeset) do
        update(changeset, :string)
    end
    defp operate("ends", changeset) do
        update(changeset, :string)
    end
    defp operate("test", changeset) do
        insert(changeset)
    end
    defp operate("and", changeset) do
        reduce(changeset)
    end
    defp operate("or", changeset) do
        reduce(changeset)
    end
    defp operate("any", changeset) do
        changeset
        |> reduce
        |> validate_length(:apply, is: 1)
    end
    defp operate(code, changeset) do
        add_error(changeset, :op, "unknown operation `#{code}`")
    end

    defp insert(changeset) do
        input = changeset
        |> Map.get(:params)
        |> Map.get("value")

        changes = changeset
        |> Map.get(:changes)
        |> Map.put(:value, input)

        types = changeset
        |> Map.get(:types)
        |> Map.put(:value, :term)

        changeset
        |> Map.put(:types, types)
        |> Map.put(:changes, changes)
        |> validate_required(:value)
    end
    defp update(changeset, type) do
        types = changeset
        |> Map.get(:types)
        |> Map.put(:value, type)

        params = changeset
        |> Map.get(:params)
        |> Map.take(["value"])

        changeset
        |> Map.put(:types, types)
        |> cast(params, [:value])
        |> validate_required(:value)
    end
    defp reduce(changeset) do
        types = changeset
        |> Map.get(:types)
        |> Map.put(:apply, @apply)

        params = changeset
        |> Map.get(:params)
        |> Map.take(["apply"])

        changeset = changeset
        |> Map.put(:types, types)
        |> cast(params, [:apply])
        |> validate_required(:apply)

        children = changeset
        |> get_change(:apply, [])
        |> Enum.map(&process/1)

        errors = children
        |> Enum.concat([changeset])
        |> Enum.map(& &1.errors)
        |> List.flatten

        valid? = errors
        |> Kernel.length
        |> Kernel.==(0)

        children = children
        |> Enum.map(&apply_changes/1)
        |> List.wrap

        changes = changeset
        |> Map.get(:changes)
        |> Map.put(:apply, children)

        changeset
        |> Map.put(:errors, errors)
        |> Map.put(:valid?, valid?)
        |> Map.put(:changes, changes)
    end

    defp transform(%{valid?: true} = changeset) do
        code = changeset
        |> get_change(:op)
        |> String.to_atom

        path = changeset
        |> get_change(:path, "")
        |> String.replace("/", ".")
        |> String.split(".")

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