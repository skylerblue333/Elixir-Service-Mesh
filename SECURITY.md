# Security

## Supported status

Sky Mesh Core is an engineering-beta library, not a production network security boundary.

## Current controls

Endpoint metadata is validated, duplicate IDs are rejected, no dynamic code evaluation is performed, CI compiles with warnings as errors, and the container runs as a non-root UID.

## Not implemented

This repository does not provide mTLS, certificate rotation, authentication, authorization, tenant isolation, encrypted transport, distributed consensus, active health probes, rate limiting, secrets storage, or production incident guarantees.

Report suspected vulnerabilities privately to the repository owner rather than publishing exploit details in a public issue.
