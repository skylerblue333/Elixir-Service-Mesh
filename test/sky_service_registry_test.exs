defmodule SkyServiceRegistryTest do
  use ExUnit.Case, async: true

  test "registers bounded service metadata without deployment claims" do
    assert {:ok, catalog, descriptor} =
             SkyServiceRegistry.register(SkyServiceRegistry.new(), "auth", %{
               name: "SkyAuth",
               version: "0.2.0",
               owner: "identity-team",
               capabilities: ["auth.verify", "identity.context"]
             })

    assert descriptor.name == "SkyAuth"
    assert descriptor.external_verification_performed == false
    assert descriptor.deployment_verified == false
    assert {:ok, fetched} = SkyServiceRegistry.get(catalog, "auth")
    assert fetched.capabilities == ["auth.verify", "identity.context"]
  end

  test "rejects duplicate services and duplicate or unsafe capabilities" do
    input = %{name: "SkyAuth", version: "1", owner: "team", capabilities: ["auth.verify"]}
    assert {:ok, catalog, _} = SkyServiceRegistry.register(%{}, "auth", input)

    assert {:error, "service already registered"} =
             SkyServiceRegistry.register(catalog, "auth", input)

    assert {:error, "capabilities must not contain duplicates"} =
             SkyServiceRegistry.register(%{}, "dup", %{
               name: "Duplicate",
               version: "1",
               owner: "team",
               capabilities: ["same", "same"]
             })

    assert {:error, "capabilities must contain 1-64 safe-character strings"} =
             SkyServiceRegistry.register(%{}, "unsafe", %{
               name: "Unsafe",
               version: "1",
               owner: "team",
               capabilities: ["../bad"]
             })
  end

  test "integrates catalog metadata with existing SkyMesh registry health state" do
    assert {:ok, catalog, _} =
             SkyServiceRegistry.register(%{}, "auth", %{
               name: "SkyAuth",
               version: "1",
               owner: "identity-team",
               capabilities: ["auth.verify"]
             })

    assert {:ok, mesh} =
             SkyMesh.register(%{}, "auth", %{
               id: "auth-1",
               host: "auth.internal",
               port: 443,
               healthy: true
             })

    assert {:ok, snapshot} = SkyServiceRegistry.routing_snapshot(catalog, mesh, "auth")
    assert snapshot.healthy_endpoint_count == 1
    assert snapshot.endpoint_health_observed_from_registry == true
    assert snapshot.external_health_probe_performed == false
    assert snapshot.deployment_verified == false
  end

  test "returns deterministic service ordering" do
    input = fn name -> %{name: name, version: "1", owner: "team", capabilities: ["health"]} end
    assert {:ok, catalog, _} = SkyServiceRegistry.register(%{}, "zeta", input.("Zeta"))
    assert {:ok, catalog, _} = SkyServiceRegistry.register(catalog, "alpha", input.("Alpha"))

    assert Enum.map(SkyServiceRegistry.list(catalog), fn {id, _} -> id end) == ["alpha", "zeta"]
  end
end
