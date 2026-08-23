# Cinnamon & Clay Platform

Cinnamon & Clay is a full-stack cafe management platform consisting of a public customer website, a mobile administration application, a Spring Boot API, PostgreSQL persistence, and S3-compatible media storage.

The system is designed as a modular monolith with clear domain boundaries, documented architectural decisions, automated testing, and production-oriented operational practices.

## Architecture

```text
                         ┌─────────────────────┐
                         │   Public Website    │
                         │      Next.js        │
                         └──────────┬──────────┘
                                    │
                                    │ REST
                                    ▼
┌─────────────────────┐   ┌─────────────────────┐
│     Admin App       │   │    Spring Boot      │
│      Flutter        │──▶│   Modular Monolith  │
└─────────────────────┘   └──────────┬──────────┘
                                     │
                         ┌───────────┴───────────┐
                         │                       │
                         ▼                       ▼
                ┌─────────────────┐     ┌─────────────────┐
                │   PostgreSQL    │     │ S3-compatible   │
                │ structured data │     │ object storage  │
                └─────────────────┘     └─────────────────┘
```

### Applications

* **`public-web`** — customer-facing website built with Next.js.
* **`admin-flutter`** — Flutter application for cafe administration.
* **`backend`** — Spring Boot REST API and domain logic.
* **`infra`** — local infrastructure and container configuration.

### Engineering documentation

* **`docs/adrs`** — Architecture Decision Records.
* **`docs/architecture`** — system, data, and delivery architecture.
* **`docs/runbooks`** — operational and recovery procedures.
* **`.github`** — CI, security automation, repository policies, and contribution workflows.

---

## Current capabilities

### Administrator security

Administrative API boundaries use OpenID Connect bearer tokens and server-side role-based authorization.

Local development uses Keycloak while the backend remains coupled to the OIDC contract rather than a provider-specific adapter.

### Public website

The public website retrieves business content from the backend rather than embedding cafe data directly in the frontend.

Current capabilities include:

* menu and pricing;
* cafe information and brand content;
* opening hours and contact information;
* social and WhatsApp links;
* managed hero, about, and gallery media;
* responsive customer-facing UI;
* runtime backend integration;
* graceful loading and error states.

### Catalog

Menu categories and items are stored in PostgreSQL and exposed through a versioned REST API.

The catalog supports:

* explicit display ordering;
* active/inactive records;
* integer minor-unit money representation;
* currency codes;
* optimistic version fields for future administrator writes.

### Content and contact information

Cafe content is managed as structured data, including:

* brand information;
* about content;
* feature highlights;
* contact details;
* opening hours;
* social links;
* WhatsApp configuration.

### Media

Media metadata is stored in PostgreSQL while image binaries are stored in S3-compatible object storage.

Local development uses MinIO.

Managed media currently supports:

* hero images;
* about-section images;
* gallery images;
* alternative text;
* display ordering;
* active/inactive state.

---

## Technology stack

| Area                      | Technology                          |
| ------------------------- | ----------------------------------- |
| Public web                | Next.js, React, TypeScript          |
| Admin application         | Flutter, Dart                       |
| Backend                   | Java 21, Spring Boot                |
| Architecture              | Spring Modulith                     |
| Persistence               | PostgreSQL                          |
| Database migrations       | Flyway                              |
| Object storage            | S3-compatible storage / MinIO       |
| Backend integration tests | Testcontainers                      |
| Local infrastructure      | Docker Compose                      |
| CI/CD                     | GitHub Actions                      |
| Security scanning         | CodeQL, Trivy, Gitleaks, Dependabot |

---

## Backend architecture

The backend is implemented as a modular monolith.

Domain capabilities are separated into modules rather than distributing the system across independently deployed services.

This keeps deployment and operations straightforward while preserving clear boundaries between areas such as:

```text
catalog
content
contact
media
reviews
identity
audit
```

Module boundaries are verified automatically using Spring Modulith architecture tests.

API endpoints are versioned under:

```text
/api/v1
```

Errors use HTTP Problem Details where applicable.

---

## Data storage

PostgreSQL stores structured business data.

Examples include:

* menu categories and items;
* site content;
* contact information;
* opening hours;
* social links;
* media metadata;
* review data.

Media binaries are stored separately in object storage.

Database schema changes are managed through immutable Flyway migrations.

See:

```text
docs/architecture/data-model.md
```

for the current persistent data model.

---

## Local development

### Prerequisites

Install:

* Git
* Docker Desktop
* Java 21
* Maven 3.6.3 or later
* Node.js 24 LTS
* npm
* Flutter stable

### Configure the environment

From the repository root:

```powershell
Copy-Item .env.example .env
```

Review `.env` before starting the services.

### Start local infrastructure

```powershell
docker compose --env-file .env -f infra/compose.yaml up -d
```

This starts the local infrastructure required for development, including PostgreSQL, MinIO and Keycloak.

Verify the local OIDC provider:

```powershell
Invoke-RestMethod `
  http://localhost:8081/realms/cinnamon-clay/.well-known/openid-configuration
```

### Run the backend

In a new terminal:

```powershell
Set-Location backend

$env:DB_URL = "jdbc:postgresql://localhost:5432/cinnamon_clay"
$env:DB_USER = "cinnamon_clay"
$env:DB_PASSWORD = "change-me-locally"

mvn spring-boot:run
```

Verify the service:

```powershell
Invoke-RestMethod http://localhost:8080/actuator/health
```

Verify the catalog API:

```powershell
Invoke-RestMethod http://localhost:8080/api/v1/catalog/menu
```

### Seed local media

After the backend has started and Flyway migrations have completed:

```powershell
powershell -ExecutionPolicy Bypass -File tools/seed-local-media.ps1
```

See:

```text
docs/runbooks/local-media-seeding.md
```

for details.

### Run the public website

In another terminal:

```powershell
Set-Location public-web

npm install

$env:BACKEND_INTERNAL_URL = "http://localhost:8080"

npm run dev
```

Open:

```text
http://localhost:3000
```

---

## Testing

### Backend

Run the complete backend verification suite:

```powershell
Set-Location backend
mvn verify
```

Backend integration tests use PostgreSQL through Testcontainers.

### Public website

```powershell
Set-Location public-web

npm run lint
npm run build
```

### Flutter application

```powershell
Set-Location admin-flutter

flutter analyze
flutter test
```

---

## Continuous integration

Pull requests are validated automatically through GitHub Actions.

Checks include:

* backend compilation and tests;
* Next.js linting and production build;
* Flutter analysis and tests;
* branch naming;
* Conventional Commit validation;
* PR title validation;
* secret scanning;
* static security analysis;
* dependency and filesystem vulnerability scanning.

Repository security automation includes:

* CodeQL;
* Gitleaks;
* Trivy;
* Dependabot.

---

## Repository conventions

Development uses short-lived branches.

Supported branch prefixes include:

```text
feat/
fix/
docs/
refactor/
test/
ci/
chore/
```

Examples:

```text
feat/admin-auth
fix/web-runtime-data
docs/readme-refresh
```

Commit messages follow Conventional Commits:

```text
feat(catalog): expose public menu endpoint
fix(web): handle backend timeout
test(media): cover inactive asset filtering
docs(architecture): update persistent data model
```

Pull-request titles follow the same convention.

---

## Architecture decisions

Significant technical decisions are recorded as ADRs under:

```text
docs/adrs
```

Topics include areas such as:

* application architecture;
* persistence;
* media storage;
* authentication;
* frontend responsibility boundaries;
* deployment and operational decisions.

ADRs document both the selected approach and the trade-offs behind it.

---

## Security

Security considerations and reporting guidance are documented in:

```text
SECURITY.md
```

The project follows several defence-in-depth practices, including:

* automated secret scanning;
* dependency vulnerability monitoring;
* static analysis;
* controlled public API exposure;
* server-side validation;
* database constraints;
* separation of public and administrative capabilities;
* planned OIDC-based administrator authentication and authorization.

Administrative write operations are not exposed publicly.

---

## Operations

Operational procedures are maintained under:

```text
docs/runbooks
```

Runbooks cover areas such as:

* local environment setup;
* media seeding;
* repository rules;
* database operations;
* backup and recovery procedures.

Additional observability, deployment, rollback, and service-level documentation will be added alongside the corresponding operational capabilities.

---

## License

See the repository license for usage terms.
