# ADR 0012: Use append-only administrator audit events

- Status: Accepted
- Date: 2026-08-24

## Context

The platform now allows administrators and editors to change catalog, site, contact, review and media data. Application logs alone are not a durable business record: they may be sampled, rotated, exported selectively, or lack a safe before/after representation.

A team lead portfolio should also demonstrate who changed what, how concurrent administration is investigated, and how security-sensitive history is protected from normal application updates.

## Decision

Record successful administrator mutations in a dedicated PostgreSQL `admin_audit_event` table in the same database transaction as the domain mutation whenever a transaction exists.

Each event records:

- an immutable UUID and database timestamp;
- OIDC subject and preferred username;
- API roles at the time of the change;
- action, resource type and resource ID;
- request ID and trace ID when available;
- bounded, sanitized before/after JSON;
- bounded metadata for operation-specific context.

Audit events are append-only. A PostgreSQL trigger rejects `UPDATE`, `DELETE`, and `TRUNCATE` on the audit table. The normal application exposes read-only administrator endpoints with bounded keyset pagination and indexed filters, including request/trace correlation IDs. Audit persistence uses explicit JDBC rather than a mutable JPA entity so normal ORM lifecycle operations cannot accidentally expose an update/delete path.

Sensitive field names containing password, secret, token, authorization or credential are redacted before persistence. Large strings, arrays and deeply nested values are bounded so the audit facility cannot become an unbounded secondary document store.

The audit record is not a replacement for centralized security logs. It is the durable application-level change history.

## Consequences

Domain mutations and their audit records normally commit or roll back together.

The audit table grows monotonically and therefore needs explicit retention/archival policy when a real production hosting target and compliance requirement exist. The application itself will not silently purge audit history.

Database administrators can still bypass application controls, so production database access must remain restricted and separately logged by the hosting platform.

Before/after snapshots improve incident investigation but increase storage usage; the bounded sanitizer keeps that cost predictable for the current scope.
