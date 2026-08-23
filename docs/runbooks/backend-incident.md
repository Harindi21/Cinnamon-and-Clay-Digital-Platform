# Backend incident triage runbook

Use this runbook when public reads, administrator writes, or platform health are degraded. It is a portfolio/local baseline; production paging, ownership and communication channels must be mapped to the eventual hosting environment.

## 1. Establish impact

Record the start time, affected capability and at least one request/reference ID when available. Determine whether the incident affects:

- public availability or only one capability;
- administrator writes only;
- media/object storage only;
- authentication/Keycloak only;
- freshness/cache invalidation while public reads remain healthy.

Do not start with a database mutation or container restart until impact and current evidence are captured.

## 2. Check service indicators

Inspect the provisioned Grafana dashboard or Prometheus directly. Check:

- backend `up` / `/actuator/health`;
- 5xx ratio and request rate;
- p95 latency;
- JVM memory;
- `cafe_public_cache_invalidation_total` outcomes;
- `cafe_admin_audit_events_total` for recent administrator activity.

For local development, `tools/smoke-local.ps1` verifies all public API capabilities and infrastructure endpoints.

## 3. Correlate the failing request

Use the response `X-Request-Id` or Problem Details `requestId`. Search backend logs for that ID. If a `traceId` exists and a collector is configured, inspect the trace.

For an administrator change, query `/api/v1/admin/audit?requestId=<id>` and compare actor/action/resource/before/after state. A missing audit event for a failed write is expected when the owning database transaction rolled back.

## 4. Check dependencies

In order of likely blast radius:

1. PostgreSQL connectivity and pool saturation;
2. Keycloak/OIDC discovery for administrator authentication problems;
3. MinIO/S3 for media-specific failures;
4. Next.js revalidation endpoint for freshness-only failures;
5. public web availability when the API itself is healthy.

Avoid deleting Docker volumes or running a destructive database restore as a diagnostic step.

## 5. Mitigate safely

Prefer the smallest reversible mitigation:

- restart only an unhealthy stateless application process when evidence supports it;
- disable optional cache revalidation/trace export if that integration is the source of latency while preserving core writes;
- hide/reactivate business content through normal administrator APIs rather than direct SQL;
- use rollback/deployment controls once the production release pipeline exists;
- use database restore only under the backup/restore runbook and with an explicit recovery decision.

## 6. Recovery verification

Before declaring recovery:

1. verify `/actuator/health`;
2. run the public API/local smoke checks;
3. verify a representative administrator read and, when safe, write;
4. confirm error rate/latency have returned to normal;
5. confirm cache invalidation outcomes are succeeding if content freshness was affected;
6. verify no unexpected media or database reconciliation work remains.

## 7. Preserve evidence and follow up

Record timeline, request/trace IDs, relevant audit event IDs, user impact, mitigation, recovery evidence and any data-integrity concern. Create a follow-up issue for root cause and preventive action rather than treating restart/retry as the root cause.
