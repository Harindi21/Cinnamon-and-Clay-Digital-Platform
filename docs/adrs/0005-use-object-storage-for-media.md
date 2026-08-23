# ADR 0005: Use object storage for media

- Status: Accepted
- Date: 2026-08-18

## Context

The demo references remote image URLs directly. Production content needs managed uploads, metadata, size/type validation and durable storage independent of application instances.

## Decision

Store image metadata in PostgreSQL and bytes in S3-compatible object storage. Use MinIO locally and a managed object store in production. Prefer signed uploads/downloads where practical.

Public media is initially read through the application API while the
storage abstraction remains independent of that delivery mechanism.

Privileged upload, replacement and lifecycle endpoints are exposed only after admin OIDC authentication and authorization. ADR 0011 defines the accepted image formats, validation limits, object-key policy, cross-store compensation and orphan reconciliation behavior.

## Consequences

- Backend instances remain stateless with respect to files.
- Media lifecycle and orphan cleanup are owned by ADR 0011; future quotas/CDN behavior still require explicit decisions if scale justifies them.
