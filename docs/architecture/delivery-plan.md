# Delivery plan - PR-sized delivery sequence

## PR 01 - repository foundation

- ADR template and initial ADRs
- CODEOWNERS, PR/issue templates
- branch and Conventional Commit policy
- CI shells, Gitleaks, Trivy, CodeQL, dependency review, Dependabot
- local PostgreSQL Compose

## PR 02 - catalog read vertical slice

- Flyway catalog schema and seed migration
- Spring Data repositories/service/controller
- Testcontainers integration test
- Spring Modulith architecture verification
- Next.js menu fetched server-side from the API
- Flutter read-only catalog screen

## PR 03 - content and contact

Migrate brand, about text/features, location, opening hours, social links and WhatsApp configuration out of the static demo. Presentation theme remains in Next.js under ADR 0007.

## PR 04 - gallery/media - complete

Media metadata and S3-compatible storage are implemented together with authenticated Flutter upload/edit/replace/hide flows, binary JPEG/PNG sniffing, byte/dimension/pixel limits, singleton Hero/About placement rules, versioned cache busting and administrator orphan reconciliation. ADR 0011 records the cross-store consistency and image-processing policy.

## PR 05 - reviews

Add review moderation/publish state and public read model.

## PR 06 - identity and authorization

Add local Keycloak, Spring Security resource server, roles/scopes, secure token handling and authenticated Flutter login.

## PR 07 - admin CRUD - complete

Create/edit/reorder/activate flows use validation and optimistic locking across catalog, reviews, content, contact and media.

## PR 08 - audit and operational readiness - complete for portfolio scope

Implemented append-only administrator audit events, request/trace correlation, production structured logging, Prometheus metrics, optional OpenTelemetry export, local Prometheus/Grafana dashboards and alerts, publish-driven Next.js cache invalidation, executable backup/restore/rehearsal tooling and operational runbooks. Provider-managed retention and production telemetry destinations remain deployment concerns.

## PR 09 - delivery

Build signed/scanned container images, SBOM/provenance, environment promotion, smoke tests and rollback procedure.

## PR 10 - release readiness and documentation

Architecture diagrams, threat model, engineering trade-offs, screenshots, demo video, performance/a11y evidence and a concise case-study README.
