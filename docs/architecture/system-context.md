# System context

```mermaid
flowchart TB
  Visitor[Website visitor]
  Admin[Cafe administrator]
  Web[Next.js public website]
  AdminApp[Flutter admin application]
  API[Spring Boot modular monolith]
  DB[(PostgreSQL)]
  Object[(S3-compatible object storage)]
  IdP[OIDC identity provider]

  Visitor --> Web
  Admin --> AdminApp
  Web -->|public REST reads| API
  AdminApp -->|authenticated REST reads/writes| API
  API --> DB
  API --> Object
  AdminApp -->|OIDC login| IdP
  API -->|JWT validation / claims| IdP
```

The implemented platform supports public REST reads from Next.js and authenticated administrator reads/writes from Flutter. PostgreSQL stores structured business data, S3-compatible storage backs the media read path, and OIDC provides administrator identity. Remaining production-readiness work is tracked in `implementation-status.md`.
