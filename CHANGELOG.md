# Changelog

## Unreleased — engineering beta

- Replace unrelated uppercase-processing demo with an actual service-registration domain.
- Add bounded service/instance registration and deterministic round-robin selection.
- Add URL and service-name validation, health/readiness endpoints and structured logging.
- Expand tests to cover selection, idempotency, validation and missing services.
- Modernize dependencies and CI with compile, Ruff, pytest, pip-audit, Docker and non-root gates.
- Remove unsupported enterprise/service-mesh/Elixir implementation claims from active documentation while retaining repository history.
