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

## PR 04 - gallery/media

Add media metadata, object storage, upload validation, image processing policy and orphan cleanup.

## PR 05 - reviews

Add review moderation/publish state and public read model.

## PR 06 - identity and authorization

Add local Keycloak, Spring Security resource server, roles/scopes, secure token handling and authenticated Flutter login.

## PR 07 - admin CRUD

Add create/edit/reorder/activate flows with optimistic locking and validation across catalog, reviews, content and contact. Media administration remains part of PR 04 completion.

## PR 08 - audit and operational readiness

Add append-only admin audit records, structured logs, metrics, dashboards, runbooks, backups and restore rehearsal.

## PR 09 - delivery

Build signed/scanned container images, SBOM/provenance, environment promotion, smoke tests and rollback procedure.

## PR 10 - release readiness and documentation

Architecture diagrams, threat model, engineering trade-offs, screenshots, demo video, performance/a11y evidence and a concise case-study README.
