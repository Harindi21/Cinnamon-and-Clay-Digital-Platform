# ADR 0011: Harden the administrator media lifecycle

- Status: Accepted
- Date: 2026-08-23

## Context

The platform already separates structured media metadata in PostgreSQL from binary content in S3-compatible object storage. The original implementation exposed only the public read path.

Administrator upload introduces a different risk profile from ordinary text CRUD:

- request bodies can be much larger;
- client-provided MIME types and filenames are untrusted;
- image decoders can be stressed by extreme dimensions;
- database and object-storage writes cannot participate in one atomic transaction;
- replacing a binary while keeping the same media ID can leave stale browser/CDN content;
- failed cross-store operations can leave orphaned objects;
- hero and About placements should not accidentally expose multiple active images.

## Decision

Provide an authenticated, versioned administrator media API and keep binary storage behind the existing `MediaStorage` abstraction.

### Upload acceptance

For the current product scope, accept JPEG and PNG only.

The backend, not Flutter, is authoritative for upload acceptance. It:

- caps multipart requests at the web-container boundary;
- enforces a second application-level byte limit;
- identifies the image format from the binary stream rather than trusting the declared MIME type or extension;
- reads image dimensions before accepting the file;
- rejects images above configured width, height or total-pixel limits;
- computes SHA-256 metadata for integrity and diagnostics;
- stores the original filename only as display metadata.

SVG is intentionally excluded because active-content handling is unnecessary for this cafe use case. Additional formats can be added only with explicit decoder and delivery support.

### Object naming

Never use a client filename as an object key.

Generated keys use the form:

```text
media/{purpose}/{yyyy}/{mm}/{uuid}.{detected-extension}
```

This prevents path traversal/name collisions and makes managed objects easy to reconcile.

### Cross-store consistency

Do not hold a PostgreSQL transaction open while uploading bytes to S3-compatible storage.

For a new upload:

1. validate bytes;
2. store a newly generated object;
3. commit metadata in a short database transaction;
4. delete the new object as compensation if metadata persistence fails.

For replacement:

1. validate and upload a new object;
2. atomically switch the metadata pointer using the supplied optimistic-lock version;
3. delete the superseded object after the database commit;
4. leave any failed cleanup to orphan reconciliation.

Object deletion is therefore best-effort cleanup, not part of the database transaction.

### Orphan reconciliation

Expose administrator-only orphan preview and cleanup operations.

An object is eligible for cleanup only when:

- it is beneath the managed `media/` prefix;
- no `media_asset` row references its object key; and
- its last-modified timestamp is older than the configured grace period.

The grace period protects uploads that have reached object storage but have not yet committed metadata.

Inactive media rows are still references and are never treated as orphans, because hide/deactivate is reversible.

### Placement invariants

`HERO` and `ABOUT` are singleton placements. Activating one asset deactivates any other active asset of the same purpose, and a partial unique PostgreSQL index provides a final concurrency guard.

`GALLERY` remains multi-valued and is ordered by `sort_order`.

### Public caching

Binary replacement keeps the stable media ID, but the media record version changes. The public media read model returns that version and Next.js includes it in the browser-facing media URL query string.

This provides cache busting after replacement without exposing object-storage keys.

### Image delivery

Store the validated source image once. Do not pre-generate an object-storage variant matrix at this stage.

The customer site already uses Next.js `Image`, which provides responsive delivery optimization. Generating and lifecycle-managing a second variant graph would add operational complexity without a current product requirement.

## Consequences

Administrator media management is end-to-end and does not rely on direct MinIO/S3 console access.

The platform has explicit limits and reconciliation behavior for an inherently non-transactional PostgreSQL/S3 workflow.

Image replacement may temporarily leave an old object when object-storage deletion fails, but cleanup is observable and recoverable.

The source image is retained at accepted resolution, so object-storage cost is slightly higher than an eager resize-only design.

If future traffic or image volume justifies dedicated transforms/CDN derivatives, that should be a separate decision with explicit lifecycle and cache semantics.
