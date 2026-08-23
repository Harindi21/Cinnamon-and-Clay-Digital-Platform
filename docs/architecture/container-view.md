# Container view

```mermaid
flowchart LR
  subgraph Clients
    WEB[public-web\nNext.js]
    ADM[admin-flutter\nFlutter]
  end

  subgraph Backend[backend · Spring Boot modular monolith]
    CATALOG[Catalog]
    CONTENT[Content]
    REVIEWS[Reviews]
    CONTACT[Contact]
    MEDIA[Media]
    AUDIT[Audit]
    PUBLISHING[Publishing]
  end

  DB[(PostgreSQL)]
  OBJ[(S3-compatible\nobject storage)]
  IDP[OIDC provider\nKeycloak locally]
  PROM[Prometheus\noptional local profile]
  GRAFANA[Grafana\noptional local profile]

  WEB -->|public REST reads| Backend
  ADM -->|authenticated REST| Backend
  ADM -->|Authorization Code + PKCE| IDP
  Backend -->|JWT issuer/claims| IDP

  CATALOG --> DB
  CONTENT --> DB
  REVIEWS --> DB
  CONTACT --> DB
  MEDIA --> DB
  MEDIA --> OBJ
  AUDIT --> DB

  CATALOG --> AUDIT
  CONTENT --> AUDIT
  REVIEWS --> AUDIT
  CONTACT --> AUDIT
  MEDIA --> AUDIT
  AUDIT -->|admin change event| PUBLISHING
  PUBLISHING -->|authenticated tag revalidation| WEB

  PROM -->|/actuator/prometheus| Backend
  GRAFANA --> PROM
```

The audit module is a durable application change log, not a replacement for centralized security/platform logs. Publishing is deliberately best-effort after commit so public cache freshness does not become part of the business transaction.
