# Observability runbook

## Local stack

Start normal infrastructure plus the optional observability profile:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up -Observability
```

Run the backend in another terminal:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 backend
```

Default endpoints:

- backend health: `http://localhost:8082/actuator/health`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

Grafana credentials come from `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` in `.env`.

The provisioned **Cinnamon & Clay · Service overview** dashboard shows backend availability, request rate, 5xx ratio, p95 latency, traffic by status, administrator change activity, JVM memory and public cache invalidation outcomes.

## Request correlation

The backend accepts a safe `X-Request-Id` or generates one. The same value is returned in the response and written to MDC.

HTTP Problem Details include `requestId` and, when tracing created one, `traceId`. Administrator audit records preserve both values.

When investigating an incident, start with the request ID because it is available even when no external trace collector is configured.

## Tracing

Tracing instrumentation is included, while OTLP export is disabled by default. Prometheus is the local metrics path; OTLP metrics export is separately opt-in with `OTLP_METRICS_ENABLED=true`, which keeps backend tests and normal local development from trying to publish to an absent collector.

Configure the production environment/collector using Spring Boot OTLP/OpenTelemetry properties and enable export. For example, an OTLP/HTTP collector can be supplied through the standard OpenTelemetry environment mapping:

```text
OTLP_TRACING_ENABLED=true
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://otel-collector.example/v1/traces
```

The production profile defaults to lower trace sampling than local development. Sampling and collector configuration are deployment concerns and should be set from environment configuration rather than committed secrets.

## Alerts

The local Prometheus rules demonstrate three actionable signals:

- backend scrape unavailable for two minutes;
- 5xx ratio above 5% for five minutes;
- p95 request latency above one second for five minutes.

These are portfolio/local baseline thresholds, not production SLO commitments. Calibrate them from real traffic before enabling paging.

## Structured logs

Default local logs remain human-readable. Run Spring with the `prod` profile to emit ECS structured console logs suitable for ingestion by a centralized log platform.
