# Administrator audit runbook

## Purpose

The audit trail is the durable application-level history of successful administrator changes. It is intentionally read-only through the API and append-only in PostgreSQL.

## Access

Only the `admin` API role can read `/api/v1/admin/audit`. Editors continue to make authorized business changes, but cannot browse organization-wide audit history.

The Flutter **Audit** destination is therefore shown only to administrators.

## Common investigation flow

1. Capture the `X-Request-Id` from the administrator/client response or HTTP Problem Details.
2. Open the Flutter Audit area or call `GET /api/v1/admin/audit`.
3. Filter by actor, action, resource type/resource ID, request ID or trace ID.
4. Open the event and compare before/after state.
5. Match `requestId` / `traceId` to backend logs or the tracing backend when configured.

Example filters:

```text
GET /api/v1/admin/audit?action=PUBLISH&resourceType=reviews.review
GET /api/v1/admin/audit?actor=local.admin&limit=25
GET /api/v1/admin/audit?resourceType=media.asset&resourceId=<uuid>
GET /api/v1/admin/audit?requestId=admin-<request-id>
```

Pagination uses an opaque cursor; callers must return the supplied `nextCursor` unchanged.

## Integrity behavior

Application code does not expose update/delete endpoints for audit events. PostgreSQL also rejects `UPDATE`, `DELETE`, and `TRUNCATE` against `admin_audit_event` through a trigger.

Do not disable the trigger as an operational shortcut. If a future retention policy requires archival/purge, implement it as a privileged, separately reviewed database procedure with documented evidence.

## Data minimization

Before/after values are sanitized and bounded before they are stored. Field names containing password, secret, token, authorization or credential are redacted.

Do not add raw bearer tokens, credentials, uploaded file bytes or arbitrary request bodies to audit metadata.
