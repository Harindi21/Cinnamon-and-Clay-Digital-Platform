# ADR 0010: Use resource-oriented admin APIs for site configuration

- Status: Accepted
- Date: 2026-08-23

## Context

Site content and contact information are small enough that the Flutter client could send one large "save all settings" document.

That approach would make unrelated edits share one concurrency boundary. An administrator changing an opening-hour row could conflict with another administrator changing the About copy, and a partial client bug could accidentally overwrite unrelated configuration.

The platform already uses per-record optimistic concurrency for administrator-managed catalog and review data.

## Decision

Expose site configuration as resource-oriented administrator APIs rather than one aggregate replacement endpoint.

The stable singleton records are updated independently:

- `/api/v1/admin/content/site`
- `/api/v1/admin/contact/profile`

Ordered child collections are managed as individual resources:

- About paragraphs;
- feature highlights;
- opening hours;
- social links.

Each mutable resource returns its current `version` and requires that version for update or deactivate operations.

Child removal is a reversible deactivate operation. Inactive rows remain visible to administrator reads but are excluded from public read models.

The API validates administrator-managed external URLs and requires HTTPS for map and social-link values. WhatsApp numbers use E.164 format when the feature is enabled.

## Consequences

Concurrent edits conflict only when administrators change the same resource.

The API is easier to audit because each mutation has a narrow business meaning.

Accidental whole-document replacement is avoided.

The Flutter client performs more API calls and contains more resource-specific editing code than a single settings form would require.

A future bulk-edit workflow should compose these resource operations explicitly rather than bypassing concurrency checks.
