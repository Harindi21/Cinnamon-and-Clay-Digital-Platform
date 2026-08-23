# Administrator catalog management runbook

The catalog administrator flow is available only to authenticated users with the `editor` or `admin` API role.

## Start local dependencies

```powershell
docker compose --env-file .env -f infra/compose.yaml up -d
```

Start the backend with the local database and OIDC settings, then start the Flutter administrator application using the OIDC runbook.

See `docs/runbooks/admin-oidc-local.md` for the sign-in flow.

## Supported operations

The administrator catalog supports:

- creating categories;
- editing category names, slugs and display order;
- hiding and reactivating categories;
- creating menu items;
- editing item name, description, category, price and display order;
- moving an item between categories;
- hiding and reactivating items.

Hiding is a soft operation. Hidden categories and items remain in the administrator API but are excluded from the public menu API.

## Verify the API boundary

Anonymous access must fail:

```powershell
try {
    Invoke-RestMethod http://localhost:8080/api/v1/admin/catalog
} catch {
    $_.Exception.Response.StatusCode
}
```

Expected status: `401`.

The public endpoint remains anonymous:

```powershell
Invoke-RestMethod http://localhost:8080/api/v1/catalog/menu
```

## Conflict handling

Every mutable catalog record contains a `version` value.

If two administrators load the same record and one saves first, the second administrator receives `409 Conflict` when attempting to save the stale version.

The Flutter application refreshes the catalog after a conflict. Re-open the editor and re-apply the intended change to the latest record.

Do not bypass version checks by manually changing request versions.

## Public visibility

Administrator changes affect PostgreSQL immediately. The public Next.js site uses a five-minute server-side revalidation window, so a recently changed menu may remain visible for up to that cache period.

Explicit publish-driven cache invalidation is handled separately from basic catalog CRUD.
