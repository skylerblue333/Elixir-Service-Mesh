# Security

This engineering-beta service registry is not a production trust boundary.

It validates service names and requires absolute HTTP(S) instance URLs, but it does not authenticate callers, authorize registrations, probe target health, prevent SSRF by downstream consumers, provide mTLS, encrypt stored state, isolate tenants, or persist an audit log.

Do not expose the registration API to untrusted networks without an external authentication/authorization layer. Consumers must independently enforce outbound-network policy before connecting to registered URLs.

The container runs as a non-root user and CI performs dependency auditing. Report vulnerabilities privately through GitHub vulnerability reporting when available rather than publishing credentials or exploit details in a public issue.
