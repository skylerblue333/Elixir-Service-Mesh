# Sky Mesh Core

A focused Elixir/OTP engineering-beta library for service registration, health filtering, and deterministic endpoint selection.

> Repository-name note: `Elixir-Service-Mesh` is the historical repository name. This project does **not** claim to be a complete transparent network mesh, sidecar proxy, Istio/Linkerd replacement, or production control plane.

## Implemented behavior

- Real Elixir implementation (`mix.exs`, `lib/sky_mesh.ex`).
- Validated endpoint records with bounded IDs/hosts and valid TCP ports.
- Duplicate endpoint rejection.
- Health-aware service discovery.
- Deterministic round-robin endpoint selection using an explicit cursor.
- ExUnit coverage for routing and validation invariants.
- CI gates for compilation with warnings-as-errors, formatting, tests, container build, and non-root runtime verification.

## Verify locally

```bash
mix compile --warnings-as-errors
mix format --check-formatted
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

## Product boundary

This checkpoint is a control-plane primitive. It has no packet proxying, mTLS, certificate issuance, persistent registry, distributed consensus, active health probing, retries, circuit breaking, traffic encryption, authorization policy, telemetry backend, Kubernetes controller, or verified deployment. Those capabilities remain future integration work and are not implied by the repository name.

## SKYCOIN4444 integration

The library can serve as a small routing/registry primitive for ecosystem services such as Sky Gateway, Identity, Chat, Queue, and workflow components. Integration should happen through stable service metadata and APIs rather than copying those applications into this repository.

## Status

**Engineering beta.** Implementation and CI verification can be considered complete only when the exact pull-request head passes all declared GitHub Actions gates.

## License

See `LICENSE`.
