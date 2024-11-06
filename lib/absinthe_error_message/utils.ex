defmodule AbsintheErrorMessage.Utils do
  @moduledoc false

  @doc """
  Returns true if the application is loaded?

  ### Examples

      iex> AbsintheErrorMessage.Utils.application_loaded?(:ecto)
      true
  """
  @spec application_loaded?(app :: atom()) :: boolean()
  def application_loaded?(app) do
    apps = Application.loaded_applications()

    case Enum.find(apps, fn {name, _, _} -> app === name end) do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Checks if the dependency version is equal to greater than the given version.

  ### Examples

      iex> AbsintheErrorMessage.Utils.meets_version_requirement?(:logger, "1.11.0")
      true
  """
  @spec meets_version_requirement?(dep :: atom(), version :: binary()) :: true | false
  def meets_version_requirement?(dep, version) do
    compare_dependency_version(dep, version) in [:eq, :gt]
  end

  @doc """
  Compares the version of a dependency.

  ### Examples

      iex> AbsintheErrorMessage.Utils.compare_dependency_version(:logger, "1.11.0")
      :gt
  """
  @spec compare_dependency_version(dep :: atom(), version :: binary()) :: :gt | :eq | :lt
  def compare_dependency_version(dep, version) do
    Application.loaded_applications()
    |> Enum.find(fn {name, _description, _version} -> name === dep end)
    |> elem(2)
    |> :binary.list_to_bin()
    |> Version.compare(version)
  end
end
