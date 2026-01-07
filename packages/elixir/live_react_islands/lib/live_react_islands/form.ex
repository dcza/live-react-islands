if Code.ensure_loaded?(Ecto.Changeset) do
  defmodule LiveReactIslands.Form do
    @moduledoc """
    Helpers for using Phoenix changesets with React islands.
    Only available when Ecto is installed.
    """

    @doc """
    Convert a changeset to full form props including schema info.
    Used by init_form/3 in the component.

    Options:
      - `:translator` - function to translate errors, defaults to app config or simple interpolation
    """
    def to_init_props(%Ecto.Changeset{} = changeset, opts \\ []) do
      schema_mod = changeset.data.__struct__

      %{
        types: get_types(schema_mod, changeset),
        required: get_required(changeset),
        values: get_values(changeset),
        errors: get_errors(changeset, opts)
      }
    end

    @doc """
    Convert a changeset to form props (values and errors only).
    Used by update_form/3 in the component.

    Options:
      - `:translator` - function to translate errors, defaults to app config or simple interpolation
    """
    def to_props(%Ecto.Changeset{} = changeset, opts \\ []) do
      %{
        values: get_values(changeset),
        errors: get_errors(changeset, opts)
      }
    end

    defp get_types(schema_mod, changeset) do
      types =
        try do
          schema_mod.__schema__(:types)
        rescue
          FunctionClauseError -> changeset.types
        end

      types
      |> stringify_keys()
      |> Enum.map(fn {k, v} -> {k, type_to_string(v)} end)
      |> Map.new()
    end

    defp type_to_string(type) when is_atom(type), do: Atom.to_string(type)
    defp type_to_string({:parameterized, {Ecto.Enum, _}}), do: "enum"
    defp type_to_string({:parameterized, _}), do: "string"
    defp type_to_string({:array, inner}), do: "array:#{type_to_string(inner)}"
    defp type_to_string(_), do: "string"

    defp get_required(changeset) do
      changeset.required
      |> Enum.map(&to_string/1)
    end

    defp get_values(changeset) do
      # Merge data and changes to get current form state
      # (includes defaults from schema + unsaved edits)
      data = Map.from_struct(changeset.data)

      Map.merge(data, changeset.changes)
      |> Map.drop([:__meta__, :id, :inserted_at, :updated_at])
      |> stringify_keys()
    end

    defp get_errors(changeset, opts) do
      translator = get_translator(opts)

      Ecto.Changeset.traverse_errors(changeset, translator)
      |> stringify_keys()
    end

    defp get_translator(opts) do
      Keyword.get_lazy(opts, :translator, fn ->
        Application.get_env(:live_react_islands, :error_translator, &default_translator/1)
      end)
    end

    defp default_translator({msg, opts}) do
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end

    defp stringify_keys(map) do
      Map.new(map, fn {k, v} -> {to_string(k), v} end)
    end
  end
end
