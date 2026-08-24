defmodule SkyMesh do
  @moduledoc """
  Deterministic service-registry and endpoint-selection primitives.

  This module is intentionally a control-plane building block, not a complete
  network service mesh or transparent proxy implementation.
  """

  @type endpoint :: %{
          required(:id) => String.t(),
          required(:host) => String.t(),
          required(:port) => pos_integer(),
          required(:healthy) => boolean()
        }

  @spec validate_endpoint(map()) :: {:ok, endpoint()} | {:error, String.t()}
  def validate_endpoint(endpoint) when is_map(endpoint) do
    with id when is_binary(id) and byte_size(id) in 1..128 <- Map.get(endpoint, :id),
         host when is_binary(host) and byte_size(host) in 1..253 <- Map.get(endpoint, :host),
         port when is_integer(port) and port in 1..65_535 <- Map.get(endpoint, :port),
         healthy when is_boolean(healthy) <- Map.get(endpoint, :healthy) do
      {:ok, %{id: id, host: host, port: port, healthy: healthy}}
    else
      _ -> {:error, "endpoint requires id, host, port 1-65535, and boolean healthy"}
    end
  end

  @spec register(map(), String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def register(registry, service, endpoint)
      when is_map(registry) and is_binary(service) and byte_size(service) in 1..128 do
    with {:ok, valid} <- validate_endpoint(endpoint) do
      endpoints = Map.get(registry, service, [])

      if Enum.any?(endpoints, &(&1.id == valid.id)) do
        {:error, "endpoint id already registered"}
      else
        {:ok, Map.put(registry, service, endpoints ++ [valid])}
      end
    end
  end

  def register(_registry, _service, _endpoint), do: {:error, "invalid registry or service name"}

  @spec healthy_endpoints(map(), String.t()) :: [endpoint()]
  def healthy_endpoints(registry, service) when is_map(registry) and is_binary(service) do
    registry
    |> Map.get(service, [])
    |> Enum.filter(& &1.healthy)
  end

  @spec choose(map(), String.t(), non_neg_integer()) :: {:ok, endpoint()} | {:error, String.t()}
  def choose(registry, service, cursor)
      when is_map(registry) and is_binary(service) and is_integer(cursor) and cursor >= 0 do
    case healthy_endpoints(registry, service) do
      [] -> {:error, "no healthy endpoints"}
      endpoints -> {:ok, Enum.at(endpoints, rem(cursor, length(endpoints)))}
    end
  end

  def choose(_registry, _service, _cursor), do: {:error, "cursor must be a non-negative integer"}
end
