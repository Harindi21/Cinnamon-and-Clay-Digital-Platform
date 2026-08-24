# System context

```mermaid
flowchart TB
  Visitor[Website visitor]
  Admin[Cafe administrator/editor]
  Web[Next.js public website]
  AdminApp[Flutter admin application]
  API[Spring Boot modular monolith]
  DB[(PostgreSQL)]
  Object[(S3-compatible object storage)]
  IdP[OIDC identity provider]
  Observability[Metrics / logs / traces]

  Visitor --> Web
  Admin --> AdminApp
  Web -->|public REST reads| API
  AdminApp -->|authenticated REST reads/writes| API
  API --> DB
  API --> Object
  AdminApp -->|OIDC login| IdP
  API -->|JWT validation / claims| IdP
  API -->|metrics / trace export / structured logs| Observability
  API -->|after-commit cache revalidation| Web
```

PostgreSQL stores structured business and append-only audit data. S3-compatible storage backs media binaries. OIDC supplies administrator identity and roles. The public Next.js application is data-cache tagged so committed administrator changes can trigger targeted revalidation while retaining a bounded TTL fallback.

Provider-specific production deployment, telemetry destinations and backup retention remain tracked in `implementation-status.md`.
