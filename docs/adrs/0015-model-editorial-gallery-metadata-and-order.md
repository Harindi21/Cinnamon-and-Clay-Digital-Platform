# ADR 0015: Model editorial gallery metadata and atomic ordering

- Status: Accepted
- Date: 2026-08-24

## Context

The original static cafe demo treated images as URLs in presentation code. The production-style platform already moved binaries to S3-compatible storage and metadata to PostgreSQL, but a professional editorial workflow needs more than placement plus alternative text.

Responsive image crops can hide the subject, gallery captions are customer-facing content, and changing several individual `sort_order` values one request at a time can expose a partially reordered gallery if an administrator stops midway or two editors race.

The public website also needs an accessible fullscreen viewing experience without reintroducing hardcoded remote image URLs.

## Decision

Extend `media_asset` with:

- optional customer-facing `caption` text;
- horizontal and vertical focal-point percentages in the inclusive range `0..100`;
- the existing optimistic `version` as the concurrency token for metadata and ordering operations.

Keep image binaries in object storage and keep all public URLs backend-owned.

Expose gallery order as a resource-oriented administrator operation:

```text
PUT /api/v1/admin/media/gallery/order
```

The request contains the complete active gallery as ordered `(id, version)` pairs and is capped at 100 entries, matching the bounded audit snapshot policy. The backend:

1. verifies the submitted asset set still equals the active gallery;
2. rejects duplicates and stale versions;
3. normalizes order values to deterministic increments;
4. flushes all order updates in one database transaction;
5. records one `REORDER` audit event for the gallery-order resource;
6. triggers the existing after-commit public-media cache invalidation.

The Flutter Media workspace provides drag-to-reorder for active gallery images and batch file selection. The public Next.js application renders an editorial responsive grid and an accessible keyboard-operable lightbox. Crop focal points are honored in hero, About, gallery thumbnails and the viewer.

Demo imagery remains developer/bootstrap content. The repository stores a manifest and downloader rather than third-party image binaries, and normal production media still enters through the authenticated media API.

## Consequences

Administrators can curate visual storytelling without changing frontend code.

Gallery order changes are atomic and concurrency-safe instead of a sequence of independent metadata writes.

Focal metadata makes responsive crops deterministic across clients.

The media public/admin contracts gain additive fields, requiring client model updates but preserving existing image IDs and URLs.

The demo downloader depends on external sources only when a developer explicitly invokes it; production runtime behavior remains independent of those sources.
