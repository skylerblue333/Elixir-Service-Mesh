# Sky Mesh Core

**Status: engineering beta.** This repository now contains a real dependency-free Elixir/OTP control-plane primitive for service endpoint registration, health filtering, and deterministic endpoint selection. The earlier Python service-registry implementation remains preserved in Git history but is no longer the active runtime on this branch.

The historical repository name is `Elixir-Service-Mesh`; this product does **not** claim to be a complete transparent network mesh, sidecar proxy, Istio/Linkerd replacement, or production control plane.

## Implemented behavior

- Real Elixir project (`mix.exs`, `lib/sky_mesh.ex`).
- Validated endpoint metadata with bounded IDs/hosts and TCP ports 1–65535.
- Duplicate endpoint ID rejection per service.
- Health-aware endpoint filtering.
- Deterministic round-robin selection using an explicit non-negative cursor.
- ExUnit coverage for routing, health filtering, validation, duplicate protection, and missing capacity.
- CI gates for warnings-as-errors compilation, formatting, tests, container build, and non-root runtime verification.

## Verify locally

```bash
mix compile --warnings-as-errors
mix format --check-formatted mix.exs "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"
mix test
docker build -t sky-mesh .
docker run --rm --entrypoint id sky-mesh -u
```

## Example

```elixir
endpoint = %{id: "chat-a", host: "chat.internal", port: 8080, healthy: true}
{:ok, registry} = SkyMesh.register(%{}, "chat", endpoint)
{:ok, selected} = SkyMesh.choose(registry, "chat", 0)
```

## Architecture boundary

`SkyMesh` is an immutable registry/selection library. Callers own persistence, active health checks, service lifecycle, discovery distribution, network transport, and authorization. Keeping the cursor explicit makes endpoint choice deterministic and leaves state ownership with the integrating service.

## SKYCOIN4444 integration

Sky Gateway, Identity, Chat, Queue, Workflow, and other ecosystem components can consume this as a small metadata/routing primitive where an Elixir component is appropriate. Integration should pass stable service metadata through explicit adapters rather than copying entire applications into this repository.

## Explicit non-goals

This checkpoint has no packet proxying, mTLS, certificate issuance, active health probes, persistent registry, distributed consensus, retries/circuit breaking, traffic encryption, authorization policy, telemetry backend, Kubernetes controller, multi-region HA, or verified production deployment. Those capabilities require separate implementation and runtime evidence.

See `SECURITY.md` and `CHANGELOG.md` for security and productization history.

## License

See `LICENSE`.
