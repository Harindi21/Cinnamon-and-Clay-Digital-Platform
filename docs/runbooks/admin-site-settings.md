# Administrator site-settings runbook

The Site tab in the Flutter administrator application manages public business content and contact information.

Theme, typography, layout and responsive behavior remain deployment-managed Next.js concerns as defined by ADR 0007.

## Required role

The administrator must hold either the `editor` or `admin` role for the `cinnamon-clay-api` OIDC client.

Anonymous calls to `/api/v1/admin/content` and `/api/v1/admin/contact` must return `401`.

## Managed resources

The Site tab supports:

- brand name, tagline, hero note, menu note and About title;
- ordered About paragraphs;
- ordered feature highlights;
- address, phone, email and map embed URL;
- WhatsApp enablement, E.164 number and prefilled message;
- ordered opening-hour rows;
- ordered social links.

Paragraphs, features, opening hours and social links use hide/reactivate semantics instead of physical deletion.

## Validation rules

Map embed URLs and social-link URLs must use HTTPS.

When WhatsApp is enabled, its number must be supplied in E.164 form, for example:

```text
+94771234567
```

The API remains the source of truth for validation even though the Flutter forms perform equivalent client-side checks for user experience.

## Conflict handling

Each editable record contains a numeric `version`.

When an administrator saves an older version after another administrator has already changed the same record, the API returns `409 Conflict` with problem type:

```text
urn:cinnamon-clay:problem:conflict
```

The Flutter application invalidates its cached settings after the conflict. Re-open the editor and apply the intended change against the refreshed record.

## Public visibility and cache window

Successful mutations are committed to PostgreSQL immediately.

The public Next.js application currently revalidates backend reads on a five-minute window, so customer-facing content can remain stale for up to that period.

Publish-driven cache invalidation is tracked as a separate production-readiness item.
