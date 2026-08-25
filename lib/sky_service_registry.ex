defmodule SkyServiceRegistry do
  @moduledoc """
  Bounded service-catalog metadata integrated with the existing `SkyMesh` endpoint registry.

  Catalog entries describe caller-supplied service metadata. Registration does not discover,
  probe, deploy, authenticate, or prove that a service actually exists.
  """

  @max_services 1_000
  @max_capabilities 32
  @id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:-]{0,95}$/
  @capability_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/

  @type descriptor :: %{
          required(:name) => String.t(),
          required(:version) => String.t(),
          required(:capabilities) => [String.t()],
          required(:owner) => String.t(),
          required(:external_verification_performed) => false,
          required(:deployment_verified) => false
        }

  @spec new() :: map()
  def new, do: %{}

  @spec register(map(), String.t(), map()) :: {:ok, map(), descriptor()} | {:error, String.t()}
  def register(catalog, service_id, input) when is_map(catalog) and is_map(input) do
    with :ok <- validate_id("service_id", service_id),
         :ok <- ensure_capacity(catalog),
         :ok <- ensure_absent(catalog, service_id),
         {:ok, descriptor} <- validate_descriptor(input) do
      {:ok, Map.put(catalog, service_id, descriptor), clone_descriptor(descriptor)}
    end
  end

  def register(_catalog, _service_id, _input), do: {:error, "catalog and descriptor must be maps"}

  @spec get(map(), String.t()) :: {:ok, descriptor()} | {:error, String.t()}
  def get(catalog, service_id) when is_map(catalog) do
    with :ok <- validate_id("service_id", service_id),
         {:ok, descriptor} <- Map.fetch(catalog, service_id) do
      {:ok, clone_descriptor(descriptor)}
    else
      :error -> {:error, "service not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec list(map()) :: [{String.t(), descriptor()}]
  def list(catalog) when is_map(catalog) do
    catalog
    |> Enum.sort_by(fn {service_id, _descriptor} -> service_id end)
    |> Enum.map(fn {service_id, descriptor} -> {service_id, clone_descriptor(descriptor)} end)
  end

  @spec routing_snapshot(map(), map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def routing_snapshot(catalog, mesh_registry, service_id)
      when is_map(catalog) and is_map(mesh_registry) do
    with {:ok, descriptor} <- get(catalog, service_id) do
      endpoints = SkyMesh.healthy_endpoints(mesh_registry, service_id)

      {:ok,
       %{
         service_id: service_id,
         descriptor: descriptor,
         healthy_endpoint_count: length(endpoints),
         endpoint_health_observed_from_registry: true,
         external_health_probe_performed: false,
         deployment_verified: false
       }}
    end
  end

  def routing_snapshot(_catalog, _mesh_registry, _service_id),
    do: {:error, "catalog and mesh registry must be maps"}

  defp validate_descriptor(input) do
    with {:ok, name} <- bounded_text("name", Map.get(input, :name), 1, 120),
         {:ok, version} <- bounded_text("version", Map.get(input, :version), 1, 64),
         {:ok, owner} <- bounded_text("owner", Map.get(input, :owner), 1, 120),
         {:ok, capabilities} <- validate_capabilities(Map.get(input, :capabilities)) do
      {:ok,
       %{
         name: name,
         version: version,
         owner: owner,
         capabilities: capabilities,
         external_verification_performed: false,
         deployment_verified: false
       }}
    end
  end

  defp validate_capabilities(values) when is_list(values) and length(values) in 1..@max_capabilities do
    values
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, acc} ->
      if is_binary(value) and Regex.match?(@capability_pattern, value) do
        if value in acc,
          do: {:halt, {:error, "capabilities must not contain duplicates"}},
          else: {:cont, {:ok, acc ++ [value]}}
      else
        {:halt, {:error, "capabilities must contain 1-64 safe-character strings"}}
      end
    end)
  end

  defp validate_capabilities(_values),
    do: {:error, "capabilities must contain 1-#{@max_capabilities} entries"}

  defp bounded_text(name, value, min, max) when is_binary(value) do
    normalized = String.trim(value)

    if String.length(normalized) in min..max,
      do: {:ok, normalized},
      else: {:error, "#{name} must be #{min}-#{max} characters"}
  end

  defp bounded_text(name, _value, min, max),
    do: {:error, "#{name} must be #{min}-#{max} characters"}

  defp validate_id(name, value) when is_binary(value) do
    if Regex.match?(@id_pattern, value),
      do: :ok,
      else: {:error, "#{name} must be 1-96 safe characters"}
  end

  defp validate_id(name, _value), do: {:error, "#{name} must be a string"}

  defp ensure_capacity(catalog) do
    if map_size(catalog) < @max_services,
      do: :ok,
      else: {:error, "service catalog capacity reached"}
  end

  defp ensure_absent(catalog, service_id) do
    if Map.has_key?(catalog, service_id),
      do: {:error, "service already registered"},
      else: :ok
  end

  defp clone_descriptor(descriptor), do: %{descriptor | capabilities: Enum.to_list(descriptor.capabilities)}
end
