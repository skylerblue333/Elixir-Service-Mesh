# Sky Service Registry

This repository's historical name is **Elixir-Service-Mesh**, but the implemented product is a small **Python/FastAPI in-memory service registry and deterministic round-robin selector**. No Elixir implementation or full service-mesh claim is made.

**Status: engineering beta.**

## Implemented behavior

- Register HTTP/HTTPS service instances by bounded service name.
- Idempotent duplicate registration.
- Deterministic round-robin instance selection.
- List registered instances.
- Health and readiness endpoints.
- Bounded registry/service capacity and URL validation.
- Thread-safe in-memory state.
- Tests, Ruff, dependency audit and non-root Docker verification in CI.

## Run

```bash
python -m pip install -r requirements.txt
uvicorn src.main:app --host 0.0.0.0 --port 8080
```

Example:

```bash
curl -X POST http://localhost:8080/api/v1/instances \
  -H 'content-type: application/json' \
  -d '{"service":"chat","url":"http://chat:8000"}'
curl http://localhost:8080/api/v1/services/chat/select
```

## Verification

```bash
python -m compileall -q src tests
ruff check src tests
python -m pytest -q
pip-audit -r requirements.txt
docker build -t sky-service-registry .
```

## Scope limitations

This is **not** Envoy, Istio, Linkerd, Consul, or a complete service mesh. It does not implement sidecars, mTLS, DNS/service discovery, health probing, distributed consensus, persistence, retries/circuit breaking, telemetry pipelines, multi-cluster routing, or production deployment.

Because registry state is process-local, restarting the service loses registrations. Multiple replicas would not share state without a future persistence/coordination layer.

## SKYCOIN4444 integration

The registry can act as a lightweight development-time discovery boundary for ecosystem services. Production integration should use a durable/authoritative discovery system and stable adapters rather than treating this in-memory registry as control-plane infrastructure.

See `SECURITY.md` and `CHANGELOG.md` for boundaries and productization history.
