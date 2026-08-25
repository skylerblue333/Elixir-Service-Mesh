# SkyServiceRegistry — Wave 2 Slot #152

**Lane:** 02  
**Status:** engineering beta / service-catalog core.

SkyServiceRegistry adds bounded service metadata and capability declarations alongside the existing SkyMesh endpoint registry. It is a deterministic control-plane data structure, not live service discovery.

## Integration contract

A catalog entry contains a bounded service ID, display name, version, owner label, and 1–32 declared capabilities. A `routing_snapshot/3` call combines catalog metadata with the healthy endpoint state already stored in `SkyMesh`.

Every descriptor explicitly reports:

- `external_verification_performed: false`
- `deployment_verified: false`

Every routing snapshot additionally reports `external_health_probe_performed: false`. Existing SkyMesh `healthy` flags are caller-supplied registry state; this product does not probe a network endpoint.

## Bounds

- at most 1,000 catalog services;
- service IDs up to 96 safe identifier characters;
- names/owners up to 120 characters;
- versions up to 64 characters;
- 1–32 unique capabilities, each up to 64 safe identifier characters.

## Explicit limitations

SkyServiceRegistry does not discover services, perform DNS, open sockets, probe health, authenticate service owners, verify deployments, manage certificates/mTLS, configure proxies, mutate infrastructure, persist the catalog, provide distributed consensus, or establish production service-mesh behavior.

A production service registry would need durable replicated state, authenticated registration, authorization, health-check semantics, lease/TTL behavior, transport security, observability, failure handling, and independent operational validation.
