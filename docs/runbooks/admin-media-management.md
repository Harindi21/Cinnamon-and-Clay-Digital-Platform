# Administrator media management runbook

## Purpose

Use the Flutter **Media** area to manage customer-facing hero, About and gallery images. Do not upload website media directly through the MinIO console during normal operation.

## Preconditions

- PostgreSQL, MinIO and Keycloak are running.
- The Spring API is running and can reach the configured media bucket.
- The Flutter administrator app is authenticated as `editor` or `admin`.
- Object-storage orphan maintenance requires the `admin` role.

## Supported upload contract

The API accepts JPEG and PNG images only.

Default local limits are:

```text
maximum binary size      8 MiB
maximum width            6000 px
maximum height           6000 px
maximum total pixels     24,000,000
orphan grace period      1 hour
```

The API sniffs the actual image format and does not trust the filename extension or multipart `Content-Type`.

## Upload an image

1. Open **Media** in the Flutter app.
2. Choose **Upload image** or the upload action within Hero, About or Gallery.
3. Select a JPEG or PNG from the native file picker.
4. Set alternative text, optional caption, crop focal point, placement, display order and active state.
5. Save.
6. Verify the image appears in the administrator list.
7. Refresh the customer website and verify the intended placement.

For Hero and About, activating a new image automatically hides the previously active image.

## Replace binary content

Use **Replace file** on the existing media record when the editorial identity, placement and alt text should remain the same.

Replacement uploads a new object first, switches the database pointer with optimistic concurrency, and removes the old object after the database commit. The media version changes so the public website gets a cache-busted URL.

A `409 Conflict` means another administrator changed the asset after it was loaded. Refresh before trying again.

## Hide and reactivate

**Hide** is reversible. It changes `active=false`; it does not delete the object or metadata row.

A hidden asset:

- is excluded from the public media API;
- remains visible in Flutter;
- keeps its object-storage reference;
- can be activated again.

## Orphan maintenance

Administrators can use the cleaning action in the Media app to preview managed object keys that are no longer referenced by any database record.

Only objects older than the configured grace period are eligible. This avoids deleting an in-flight upload between its object-store write and metadata commit.

Review the preview before confirming deletion.

Equivalent API operations are:

```text
GET    /api/v1/admin/media/orphans
DELETE /api/v1/admin/media/orphans
```

These operations require the `admin` role.

## Troubleshooting

### Upload returns 400

Check the Problem Details response. Common reasons are unsupported/corrupt image data or dimension safety limits.

### Upload returns 413

The multipart request exceeded the configured container-level limit. Resize/compress the source image or change the limit intentionally through environment configuration.

### Image is visible in Flutter but not public

Confirm `active=true` and the placement. Hidden records are deliberately not public.

### Public browser still shows an old replacement

First verify `/api/v1/media` returns the new media `version`. The Next.js media URL includes that version for cache busting. If public metadata itself is stale, verify `PUBLIC_REVALIDATION_ENABLED`, the revalidation URL/secret, and the backend cache-invalidation metric/logs. The five-minute tagged-cache TTL remains the safety fallback.

### Superseded object remains in MinIO

A best-effort cleanup may have failed after metadata committed. Use administrator orphan preview after the grace period, then run orphan cleanup.

## Curate the public gallery

Active `GALLERY` assets are shown in a dedicated reorderable list in Flutter.

1. Open **Media → Gallery**.
2. Drag active items into the intended customer-facing sequence.
3. Release the item; the client submits the complete active gallery with optimistic versions.
4. If another administrator changed the gallery first, the API returns `409 Conflict`; refresh and reorder again.
5. Verify the public website. Cache invalidation runs after the committed audit event and the five-minute metadata TTL remains the fallback.

The backend normalizes public gallery sort values to increments of ten. Do not rely on the numeric values as business identifiers.

## Captions and crop focal points

**Alternative text** is accessibility metadata and should describe meaningful image content.

**Public caption** is optional editorial copy rendered with gallery imagery. Do not duplicate alt text mechanically when a short customer-facing caption is more useful.

**Horizontal/vertical focal point** controls where responsive crops keep the subject. `50 / 50` is the center. Move horizontal focus toward `0` for the left side or `100` for the right; move vertical focus toward `0` for the top or `100` for the bottom.

## Batch gallery upload

Flutter supports selecting several gallery files in one picker operation. Batch upload intentionally uses the existing authenticated single-asset API for every file so normal binary validation, audit recording and object-storage rollback behavior are preserved.

The initial batch metadata is:

- placement `GALLERY`;
- active `true`;
- centered crop focus;
- filename-derived alternative text;
- order appended after the current active gallery.

Review each new asset afterward and improve alt text, caption and focal position where needed.

## Restore the original demo imagery locally

The repository does not commit third-party demo binaries. To download the remote imagery referenced by the original static prototype into an ignored local folder:

```powershell
powershell -ExecutionPolicy Bypass -File tools/prepare-demo-media.ps1
```

The files are written under `.local/demo-media`. Use Flutter's Gallery **Upload batch** action for the six gallery files, then upload `hero-cafe.jpg` and `about-cafe.jpg` into their singleton placements.

For automation in a local environment, the script can also call the authenticated media API when supplied an administrator access token:

```powershell
powershell -ExecutionPolicy Bypass -File tools/prepare-demo-media.ps1 `
  -Upload `
  -AccessToken '<local-admin-access-token>'
```

The manifest deliberately records the external source URLs instead of copying those binaries into Git. Review licensing/attribution requirements before redistributing third-party images or using them outside a local portfolio demonstration.
