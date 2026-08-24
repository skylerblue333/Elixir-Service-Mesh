defmodule SkyMeshTest do
  use ExUnit.Case, async: true

  test "registers and selects healthy endpoints deterministically" do
    endpoint_a = %{id: "a", host: "service-a", port: 8080, healthy: true}
    endpoint_b = %{id: "b", host: "service-b", port: 8081, healthy: true}

    assert {:ok, registry} = SkyMesh.register(%{}, "feed", endpoint_a)
    assert {:ok, registry} = SkyMesh.register(registry, "feed", endpoint_b)
    assert {:ok, %{id: "a"}} = SkyMesh.choose(registry, "feed", 0)
    assert {:ok, %{id: "b"}} = SkyMesh.choose(registry, "feed", 1)
    assert {:ok, %{id: "a"}} = SkyMesh.choose(registry, "feed", 2)
  end

  test "filters unhealthy endpoints" do
    registry = %{
      "chat" => [
        %{id: "a", host: "a", port: 9000, healthy: false},
        %{id: "b", host: "b", port: 9001, healthy: true}
      ]
    }

    assert [%{id: "b"}] = SkyMesh.healthy_endpoints(registry, "chat")
    assert {:ok, %{id: "b"}} = SkyMesh.choose(registry, "chat", 99)
  end

  test "rejects invalid and duplicate endpoints" do
    assert {:error, _} = SkyMesh.validate_endpoint(%{id: "x", host: "x", port: 0, healthy: true})
    assert {:ok, registry} = SkyMesh.register(%{}, "identity", %{id: "x", host: "id", port: 443, healthy: true})
    assert {:error, "endpoint id already registered"} =
             SkyMesh.register(registry, "identity", %{id: "x", host: "other", port: 8443, healthy: true})
  end

  test "reports missing healthy capacity" do
    assert {:error, "no healthy endpoints"} = SkyMesh.choose(%{}, "missing", 0)
    assert {:error, _} = SkyMesh.choose(%{}, "missing", -1)
  end
end
