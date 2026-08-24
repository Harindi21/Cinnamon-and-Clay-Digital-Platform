# Implementation status

This document keeps portfolio claims aligned with code that exists in the repository. “Complete for portfolio scope” means the capability is implemented and demonstrable in this repository; provider-specific production configuration may still remain.

| Capability | Status | Evidence / remaining work |
| --- | --- | --- |
| Repository engineering | Complete | PR templates, CODEOWNERS, branch/commit policy, Dependabot, CI and security workflows are present. |
| Public catalog | Complete | PostgreSQL + Flyway, Spring REST API, Next.js consumption and integration tests. |
| Public content/contact | Complete | Brand/about/contact/hours/social/WhatsApp data is persisted and read through versioned APIs. |
| Admin catalog | Complete | Flutter CRUD, validation, soft hide/reactivate and optimistic concurrency. |
| Admin content/contact | Complete | Flutter Site settings management with resource-level optimistic concurrency. |
| Reviews | Complete | Draft/published/hidden lifecycle, public filtering and Flutter moderation. |
| OIDC/RBAC | Complete for portfolio scope | Keycloak local environment, PKCE native login, JWT resource server and API-client roles. Production IdP/environment configuration remains deployment work. |
| Native admin runner | Partial | Flutter/Dart application code and `tool/bootstrap_android.ps1` are present, but the generated/reviewed `admin-flutter/android/` runner still needs to be committed for clone-and-run Android builds. |
| Media lifecycle | Complete for portfolio scope | S3-compatible storage + PostgreSQL metadata, Flutter upload/edit/replace/hide, binary sniffing, byte/dimension/pixel limits, SHA-256 metadata, singleton placement invariants, versioned cache busting and admin-only orphan reconciliation. |
| Administrator audit trail | Complete for portfolio scope | Append-only PostgreSQL audit events, OIDC actor/roles, safe before/after state, request/trace correlation, bounded keyset query API and administrator-only Flutter viewer. Retention/archival policy remains a production governance decision. |
| Public cache freshness | Complete for portfolio scope | Next.js capability tags plus authenticated best-effort after-commit revalidation. Five-minute fetch TTL remains the failure fallback. |
| Observability | Complete for portfolio scope | Request IDs, trace/span correlation, Problem Details correlation, Prometheus metrics, optional OpenTelemetry export, ECS production logs, local Prometheus/Grafana profile, dashboard and alert rules. Production collector/destination and alert calibration remain deployment work. |
| Backup / recovery | Partial-to-strong | Executable backup, destructive restore and isolated restore-rehearsal scripts exist with checksum metadata and schema/table verification. Automated encrypted/off-site retention, PITR and measured production RPO/RTO remain provider work. |
| Delivery pipeline | Partial | Non-root Dockerfiles, CI/security checks and operational-config validation exist. Image publication, immutable digest promotion, SBOM/provenance, signing, deployment smoke tests and rollback automation remain. |
| End-to-end quality | Partial | Backend integration and Flutter unit/widget tests exist. Browser E2E, admin integration tests, performance budgets and accessibility evidence remain. |
| Portfolio release package | Partial | ADRs, diagrams, threat model, runbooks and operational dashboard exist. Final screenshots, demo video, measured quality evidence, tagged release and case-study summary remain. |

## Recommended next sequence

1. Commit/review the generated Android runner so the admin application is clone-and-run.
2. Build the release workflow: immutable image tags, registry publication, SBOM/provenance, signing, environment promotion, smoke tests and rollback.
3. Add browser/admin E2E tests plus Lighthouse/accessibility/performance evidence.
4. Rehearse backup/restore and capture real local evidence; later replace local objectives with provider-backed RPO/RTO evidence.
5. Produce the portfolio release: screenshots, demo video, tagged release and concise engineering case study.
