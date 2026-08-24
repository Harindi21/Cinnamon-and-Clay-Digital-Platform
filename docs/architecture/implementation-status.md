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
| Native admin runner | Complete for Android portfolio scope | Committed Android host, API 24 baseline, AppAuth callback, debug-only cleartext policy, backup exclusion, environment-only release signing, PR APK/AAB builds and path-scoped emulator launch/callback smoke. External-browser Keycloak login remains a human-in-the-loop device check. |
| Media lifecycle | Complete for portfolio scope | S3-compatible storage + PostgreSQL metadata, Flutter single/batch upload, edit/replace/hide, atomic drag-to-reorder gallery, captions/focal points, binary sniffing, byte/dimension/pixel limits, SHA-256 metadata, singleton placement invariants, versioned cache busting and admin-only orphan reconciliation. |
| Administrator audit trail | Complete for portfolio scope | Append-only PostgreSQL audit events, OIDC actor/roles, safe before/after state, request/trace correlation, bounded keyset query API and administrator-only Flutter viewer. Retention/archival policy remains a production governance decision. |
| Public cache freshness | Complete for portfolio scope | Next.js capability tags plus authenticated best-effort after-commit revalidation. Five-minute fetch TTL remains the failure fallback. |
| Observability | Complete for portfolio scope | Request IDs, trace/span correlation, Problem Details correlation, Prometheus metrics, optional OpenTelemetry export, ECS production logs, local Prometheus/Grafana profile, dashboard and alert rules. Production collector/destination and alert calibration remain deployment work. |
| Backup / recovery | Partial-to-strong | Executable backup, destructive restore and isolated restore-rehearsal scripts exist with checksum metadata and schema/table verification. Automated encrypted/off-site retention, PITR and measured production RPO/RTO remain provider work. |
| Delivery pipeline | Complete for provider-neutral portfolio scope | Production container builds are PR-validated; SemVer releases publish GHCR images, BuildKit provenance/SBOM attestations, CycloneDX SBOMs, Trivy gates, keyless Cosign signatures and immutable release manifests. GitHub Environment promotion verifies signatures/digests and emits deployment manifests. A cloud/provider deployment adapter remains environment work. |
| End-to-end quality | Strong | Backend integration + Flutter tests, built Next.js Chromium E2E/Lighthouse budgets, Android APK/AAB assembly, AppAuth manifest verification and emulator launch smoke are automated. External-browser credential entry is intentionally kept out of CI. |
| Portfolio release package | Partial | ADRs, diagrams, threat model, runbooks and operational dashboard exist. Final screenshots, demo video, measured quality evidence, tagged release and case-study summary remain. |

## Recommended next sequence

1. Run `tools/admin-android-smoke.ps1`, complete one real Keycloak browser login on an emulator/device and capture evidence.
2. Configure GitHub Environments (`staging`, `production`, `mobile-release`) and exercise signed server + Android release rehearsals.
3. Rehearse backup/restore and capture measured local recovery evidence; later replace local objectives with provider-backed RPO/RTO evidence.
4. Add the chosen cloud/provider deployment adapter and production secrets/telemetry destinations.
5. Produce the portfolio release: screenshots, demo video, tagged release and concise engineering case study.
