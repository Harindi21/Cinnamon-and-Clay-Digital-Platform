# Security policy

Do not report secrets or exploitable vulnerabilities in a public issue.

Use a private GitHub Security Advisory when available. If a secret is committed, treat it as compromised: revoke/rotate it first, then remove it from repository history if necessary.

## Implemented controls

Repository and supply-chain controls include Gitleaks, CodeQL, Trivy, dependency review, Dependabot, least-privilege workflow permissions and protected-branch/ruleset expectations.

Application controls include:

- OIDC bearer-token validation and server-side administrator/editor RBAC;
- explicit administrator DTOs and bean validation;
- optimistic concurrency for administrator-managed resources;
- hardened JPEG/PNG upload validation and generated object keys;
- append-only administrator audit records with bounded/redacted before/after state;
- request/trace correlation without persisting bearer tokens;
- authenticated allow-listed public cache revalidation;
- PostgreSQL constraints and forward-only Flyway migrations.

Local `.env` values are development placeholders only. Production environments must provide unique secrets for database/object-storage/OIDC/cache-revalidation/Grafana access through an appropriate secret manager or protected environment configuration.

See `docs/architecture/threat-model.md` for the current control/backlog model and `docs/runbooks/secret-leak.md` for secret-response steps.
