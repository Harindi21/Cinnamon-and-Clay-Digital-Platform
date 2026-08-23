# Implementation status

This document keeps portfolio claims aligned with code that exists in the repository.

| Capability | Status | Evidence / remaining work |
| --- | --- | --- |
| Repository engineering | Complete | PR templates, CODEOWNERS, branch/commit policy, Dependabot and security workflows are present. |
| Public catalog | Complete | PostgreSQL + Flyway, Spring REST API, Next.js consumption and integration tests. |
| Public content/contact | Complete | Brand/about/contact/hours/social/WhatsApp data is persisted and read through versioned APIs. |
| Admin catalog | Complete | Flutter CRUD, validation, soft hide/reactivate and optimistic concurrency. |
| Admin content/contact | Complete | Flutter Site settings management with resource-level optimistic concurrency. |
| Reviews | Complete | Draft/published/hidden lifecycle, public filtering and Flutter moderation. |
| OIDC/RBAC | Complete for portfolio scope | Keycloak local environment, PKCE native login, JWT resource server and API-client roles. Production IdP/environment configuration remains deployment work. |
| Media public read path | Partial | Metadata model, S3-compatible storage abstraction and public streaming exist. Admin upload/update/delete flow, MIME/size/dimension validation, image processing and orphan cleanup are still required. |
| Observability | Partial | Actuator health and Prometheus endpoint exist. Structured JSON logging, trace propagation, dashboards and alerting are not complete. |
| Audit trail | Not started | Append-only administrator audit records and actor/change metadata are still required. |
| Backup / recovery | Partial | Runbook exists. Automated backups, restore rehearsal evidence and recovery objectives remain. |
| Delivery pipeline | Partial | Non-root Dockerfiles and CI checks exist. Image publication, SBOM/provenance, signing, environment promotion, smoke tests and rollback automation remain. |
| End-to-end quality | Partial | Backend integration and Flutter unit/widget tests exist. Browser E2E, admin integration tests, performance budgets and accessibility evidence remain. |
| Portfolio release package | Partial | ADRs, diagrams, threat model and runbooks exist. Final screenshots, demo video, architecture narrative, measured quality evidence and case-study summary remain. |

## Recommended next sequence

1. Complete administrator media management and upload hardening.
2. Add append-only admin audit events with actor, action, target, timestamp and safe before/after metadata.
3. Add cache invalidation for successful content publication instead of relying only on the five-minute public revalidation window.
4. Add structured logging/tracing, dashboards and a small set of service-level indicators.
5. Build the release workflow: immutable image tags, SBOM/provenance, signing, environment promotion, smoke test and rollback.
6. Add browser/admin E2E tests plus Lighthouse/accessibility evidence.
7. Produce the portfolio release: screenshots, demo video and concise case study.
