# Security

## Status

Sky Mesh Core is an **engineering-beta Elixir library**, not a production network security boundary.

## Current controls

- Endpoint IDs and host strings are bounded; ports must be valid TCP ports.
- Duplicate endpoint IDs within a service are rejected.
- Selection only returns endpoints explicitly marked healthy by the caller.
- The library performs no dynamic code evaluation or shell execution.
- CI compiles with warnings as errors, checks formatting, runs ExUnit tests, builds the container, and verifies a non-root runtime user.
- The active implementation has no third-party Mix dependencies.

## Boundaries

This repository does not authenticate or authorize callers, actively probe endpoint health, validate DNS/IP ownership, provide mTLS, rotate certificates, encrypt service traffic, persist registry state, distribute state through consensus, enforce tenant isolation, apply network policy, or maintain a durable audit log.

Callers remain responsible for treating endpoint metadata as untrusted configuration and enforcing outbound-network, identity, TLS, and authorization policy before connecting to selected endpoints.

## Reporting

Use GitHub private vulnerability reporting when available. Do not publish credentials, private topology data, or working exploit details in public issues.
