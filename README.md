# Cinnamon & Clay Digital Platform

Cinnamon & Clay is a portfolio-grade cafe digital platform with a customer website, a native administration application, a Spring Boot modular-monolith API, PostgreSQL, OIDC-based administrator security, and S3-compatible media storage.

The repository is deliberately organized around **end-to-end product slices plus operational evidence** rather than a technology showcase. Architecture decisions, concurrency rules, threat controls, auditability, recovery procedures and CI policy live beside the code.

## System at a glance

```text
                                ┌──────────────────────┐
                                │ Customer Website     │
                                │ Next.js              │
                                └──────────┬───────────┘
                                           │ public REST
                                           │ + tagged cache
                                           ▼
┌──────────────────────┐       ┌─────────────────────────────┐
│ Flutter Admin        │──────▶│ Spring Boot Modular Monolith│
│ OIDC + PKCE          │ JWT   │ Java 21 / REST / Actuator  │
└──────────┬───────────┘       └───────┬───────────┬─────────┘
           │                            │           │
           ▼                            ▼           ▼
┌──────────────────────┐       ┌──────────────┐  ┌──────────────────┐
│ OIDC Provider        │       │ PostgreSQL   │  │ S3-compatible    │
│ Keycloak locally     │       │ + audit log  │  │ media / MinIO    │
└──────────────────────┘       └──────────────┘  └──────────────────┘
                                           │
                                ┌───────────▼───────────┐
                                │ Prometheus / Grafana  │
                                │ optional local profile│
                                └───────────────────────┘
```

## Applications

- **`public-web`** — Next.js customer-facing website.
- **`admin-flutter`** — Flutter administrator/editor application.
- **`backend`** — Spring Boot REST API and modular domain logic.
- **`infra`** — PostgreSQL, MinIO, Keycloak and optional observability infrastructure.
- **`tools`** — repeatable local-development and database recovery scripts.
- **`docs`** — ADRs, architecture views, threat model, operational objectives and runbooks.

## Implemented capabilities

### Customer experience

- database-backed menu and pricing;
- persisted brand/about/contact/opening-hours/social/WhatsApp content;
- managed Hero/About/Gallery media;
- published reviews only;
- responsive Next.js presentation with explicit error handling;
- capability-tagged server cache with a five-minute safety TTL;
- targeted after-commit revalidation when administrators publish changes.

### Administrator application

- OIDC Authorization Code + PKCE login;
- server-side `EDITOR` / `ADMIN` authorization;
- catalog create/edit/reorder/hide/reactivate;
- site/content/contact/opening-hour/social management;
- review create/edit/publish/hide lifecycle;
- media upload/edit/replace/hide/reactivate and administrator orphan cleanup;
- resource-level optimistic concurrency with `409` conflict handling;
- administrator-only searchable audit trail with before/after details.

### Media safety

Media binaries live in S3-compatible object storage while PostgreSQL stores metadata and object keys. The backend:

- accepts JPEG/PNG for the current product scope;
- validates the binary signature rather than trusting filename/MIME claims;
- enforces request byte, image dimension and total-pixel limits;
- generates server-owned object keys;
- stores SHA-256 metadata;
- uses new-object-then-metadata-switch replacement semantics;
- compensates failed cross-store writes and provides aged orphan reconciliation;
- enforces single active Hero/About placements in application and database constraints.

See `docs/adrs/0011-harden-admin-media-lifecycle.md`.

### Auditability and operations

Successful administrator changes produce append-only PostgreSQL audit events containing actor identity/roles, action/resource, bounded sanitized before/after state, request ID and trace ID. PostgreSQL rejects update/delete/truncate of the audit table.

Operational instrumentation includes:

- `X-Request-Id` propagation/generation;
- request/trace IDs in HTTP Problem Details;
- Spring tracing instrumentation with optional OTLP export;
- Prometheus Actuator metrics plus application counters;
- ECS structured console logs in the production profile;
- optional local Prometheus/Grafana stack, dashboard and alert rules;
- executable PostgreSQL backup, restore and isolated restore-rehearsal scripts.

See `docs/adrs/0012-use-append-only-administrator-audit-events.md`, `docs/adrs/0013-use-after-commit-public-cache-invalidation.md`, `docs/adrs/0014-standardize-correlation-metrics-and-local-observability.md`, and `docs/runbooks/backend-incident.md`.

## Technology stack

| Area | Technology |
| --- | --- |
| Public web | Next.js 16, React 19, TypeScript |
| Admin application | Flutter, Dart, Riverpod, Dio |
| Backend | Java 21, Spring Boot 4, Spring Modulith |
| Persistence | PostgreSQL 18, Flyway |
| Identity | OIDC/OAuth2 resource server, Keycloak locally |
| Media | S3-compatible API / MinIO locally |
| Testing | JUnit, MockMvc, Testcontainers, Flutter tests |
| Metrics | Micrometer, Prometheus, Grafana |
| Tracing | Spring Boot OpenTelemetry instrumentation, opt-in OTLP export |
| CI/security | GitHub Actions, CodeQL, Trivy, Gitleaks, Dependabot |

## Backend module boundaries

The backend remains a modular monolith rather than being split into premature microservices:

```text
catalog
content
contact
media
reviews
identity
audit
publishing
shared
```

Spring Modulith architecture verification runs in the backend test suite. Public and administrator APIs are versioned under `/api/v1`.

## Local development

### Prerequisites

Install Git, Docker Desktop, Java 21, Maven, Node.js 24+, npm and Flutter stable. Android administration also requires the Android SDK/ADB and an emulator or device.

### 1. Configure

From the repository root:

```powershell
Copy-Item .env.example .env
```

The checked-in local defaults intentionally avoid common workstation conflicts:

```text
PostgreSQL host port  55432
Spring Boot           8082
Keycloak              8081
Next.js               3000
MinIO API             9000
MinIO console         9001
Grafana               3001 (optional)
Prometheus             9090 (optional)
```

All values are environment-configurable.

### 2. Start infrastructure

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up
```

With the local observability stack:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up -Observability
```

### 3. Start the backend

In terminal 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 backend
```

Verify:

```powershell
Invoke-RestMethod http://localhost:8082/actuator/health
Invoke-RestMethod http://localhost:8082/api/v1/catalog/menu
```

### 4. Start the customer website

Install dependencies once:

```powershell
Set-Location public-web
npm ci
Set-Location ..
```

Then, in terminal 3:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 web
```

Open `http://localhost:3000`.

The launcher points Next.js to the configured backend port, so developers do not need to manually synchronize terminal-only `DB_*` / backend URL variables.

### 5. Start the Flutter admin

The generated Android runner is still an explicit repository packaging task. Generate it once if `admin-flutter/android/` is absent:

```powershell
Set-Location admin-flutter
powershell -ExecutionPolicy Bypass -File tool/bootstrap_android.ps1
Set-Location ..
```

Start an emulator/device, then:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 admin
```

The launcher configures ADB reverse mappings and the local API/OIDC `dart-define` values.

See `docs/runbooks/local-development.md` and `docs/runbooks/admin-oidc-local.md`.

## Local observability

Start with `-Observability`, then open:

```text
Prometheus  http://localhost:9090
Grafana     http://localhost:3001
```

Grafana is provisioned with the **Cinnamon & Clay · Service overview** dashboard. Local alert rules cover backend unavailability, elevated 5xx ratio and p95 latency guardrails.

These are operational design controls, not claims about measured production SLO achievement. See `docs/architecture/service-level-objectives.md`.

## Database backup / recovery

Create a custom-format PostgreSQL backup plus SHA-256 metadata:

```powershell
powershell -ExecutionPolicy Bypass -File tools/backup-db.ps1
```

Rehearse a restore into an isolated temporary database:

```powershell
powershell -ExecutionPolicy Bypass -File tools/rehearse-restore.ps1 `
  -BackupPath backups/cinnamon_clay-<timestamp>.dump
```

A destructive development restore requires an explicit `-Force` flag. See `docs/runbooks/database-backup-restore.md` before using it.

## Testing

Backend:

```powershell
Set-Location backend
mvn verify
```

Public web:

```powershell
Set-Location public-web
npm ci
npm run lint
npm run build
```

Flutter:

```powershell
Set-Location admin-flutter
flutter analyze
flutter test
```

CI also validates Docker Compose, Prometheus rules/config, Grafana dashboard JSON and PowerShell script syntax. With the local stack running, a lightweight HTTP smoke check is available:

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke-local.ps1 -IncludeWeb
```

## Repository policy and security

Short-lived branches and Conventional Commits are enforced on pull requests. Examples:

```text
feat/audit-operational-readiness
fix/web-backend-timeout
ci/validate-observability
```

```text
feat(audit): add append-only administrator history
test(audit): cover authorization and pagination
docs(operations): add restore rehearsal runbook
```

Security automation includes CodeQL, Gitleaks, Trivy, dependency review and Dependabot. Administrator APIs enforce server-side RBAC; tokens are not stored by the backend; normal destructive business actions are reversible where product semantics permit it.

See `SECURITY.md` and `docs/architecture/threat-model.md`.

## Architecture decisions

Significant decisions are recorded as ADRs under `docs/adrs`, including modular-monolith architecture, versioned REST, PostgreSQL/Flyway, OIDC, object storage, client presentation boundaries, authorization, optimistic concurrency, resource-oriented site administration, hardened media lifecycle, append-only auditing, cache invalidation and observability.

## Delivery status

The strongest remaining gaps are no longer core CRUD. They are release engineering and portfolio evidence:

1. commit/review the native Android runner;
2. publish/sign immutable container images with SBOM/provenance and controlled promotion/rollback;
3. add browser/admin E2E, accessibility and performance-budget evidence;
4. capture a real restore rehearsal and production-like recovery objectives;
5. create the final tagged portfolio release with screenshots, demo video and case-study narrative.

See `docs/architecture/implementation-status.md` for the claim-by-claim status matrix.

## License

See the repository license for usage terms.
