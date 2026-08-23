# ADR 0009: Use optimistic concurrency for administrator writes

- Status: Accepted
- Date: 2026-08-23

## Context

Administrators can keep an edit form open while another administrator changes the same record.

Silently accepting an older edit would overwrite the newer change and make the loss difficult to detect.

The expected administrator workload is small and does not justify pessimistic database locks or long-lived edit sessions.

## Decision

Administrator-managed mutable records carry a numeric `version` field backed by JPA `@Version` columns.

Read models returned to the administrator application include the current version.

Update and deactivate requests send the version that was originally loaded.
Update request contracts require the version field explicitly; an omitted version is a validation error and must not silently default to version `0`.

The API compares the supplied version with the current persisted version before applying a change. A mismatch returns HTTP `409 Conflict` using the problem type:

```text
urn:cinnamon-clay:problem:conflict
```

The Flutter administrator application treats `409` as a stale-edit signal, refreshes the catalog, and asks the administrator to retry against the latest data.

Catalog delete actions are implemented as deactivation rather than physical deletion. This preserves references and makes accidental removal reversible through a later edit.

## Consequences

Concurrent changes are detected instead of silently overwritten.

The API contract includes version metadata on administrator write models.

Clients must refresh after a conflict before retrying.

Database migrations are required when an existing mutable table does not already contain a version column.

Physical deletion remains a separate operation and should only be introduced when retention and audit requirements are explicitly defined.
