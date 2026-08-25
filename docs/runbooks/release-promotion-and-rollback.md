# Release, promotion and rollback runbook

## Purpose

This runbook defines the provider-neutral release boundary. It distinguishes image creation from environment authorization, prevents hand-copied digest/revision drift and keeps rollback coordinates immutable.

## Create a release candidate

Preferred path: push an annotated SemVer tag from a commit already reachable from `main`, for example `v1.0.0-rc.1`. The **Release** workflow rejects tag events outside `main`, reruns source verification, builds backend/public-web images, publishes to GHCR, scans them, emits CycloneDX SBOMs, records BuildKit provenance/SBOM attestations and keyless-signs each digest with Cosign.

For pipeline rehearsal without a Git tag, dispatch **Release** manually with a SemVer value. Manual runs publish the same signed image artifacts to GHCR and retain the release bundle as a workflow artifact, but they do **not** create a GitHub Release and are intentionally not eligible for staging/production promotion.

A published tagged release exposes:

- `release-manifest.json` — source revision, version, image references/digests and SBOM filenames;
- `release-manifest.json.sha256` — transport/integrity check for the manifest asset;
- backend/public-web CycloneDX SBOMs.

The image digest is the deployment identity. The Git tag is the human-friendly authorization coordinate used to locate and bind the manifest.

## Verify locally

Download `release-manifest.json` from the GitHub Release and run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-release-manifest.ps1 `
  -ManifestPath .\release-manifest.json `
  -ExpectedReleaseVersion 1.0.0 `
  -ExpectedRepository Harindi21/Cinnamon-and-Clay-Digital-Platform
```

If you also know the source commit from `git rev-list -n 1 v1.0.0`, verify it explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-release-manifest.ps1 `
  -ManifestPath .\release-manifest.json `
  -ExpectedReleaseVersion 1.0.0 `
  -ExpectedRepository Harindi21/Cinnamon-and-Clay-Digital-Platform `
  -ExpectedSourceRevision <40-character-sha>
```

With Cosign installed and registry access configured, verify that both images were signed by this repository's release workflow for the exact tag:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-release-manifest.ps1 `
  -ManifestPath .\release-manifest.json `
  -ExpectedReleaseVersion 1.0.0 `
  -ExpectedRepository Harindi21/Cinnamon-and-Clay-Digital-Platform `
  -ReleaseTag v1.0.0 `
  -VerifySignatures
```

## Promote

1. Configure GitHub Environments named `staging` and `production`; production should require a reviewer.
2. Open **Actions -> Promote immutable release -> Run workflow**.
3. Choose the target environment.
4. Enter the tagged release version without the leading `v`, for example `1.0.0-rc.1`.
5. Approve the GitHub Environment gate when appropriate.
6. The workflow resolves `v<version>`, requires a published GitHub Release, downloads its manifest/checksum and verifies:
   - the tag commit is still reachable from `main`;
   - requested SemVer and release-manifest version match;
   - the manifest source revision is the commit resolved by the tag;
   - backend/public-web references are the repository-owned GHCR names;
   - both digests are immutable SHA-256 values;
   - manifest checksum is valid;
   - both Cosign signatures were issued by `.github/workflows/release.yml` for that exact tag;
   - both referenced digests still exist in GHCR.
7. The workflow emits `deployment-manifest.json` plus the exact release manifest/checksum used as promotion evidence.
8. The provider deployment adapter must deploy the two `ref@sha256:digest` values from that deployment manifest and then run an environment smoke check.

No build occurs during promotion, and operators do not manually type image digests or source revisions.

## Smoke criteria

At minimum after deployment verify:

- backend `/actuator/health/readiness` returns 200/UP;
- public web `/api/health/ready` returns 200/UP;
- public catalog/content/contact/media/reviews return 2xx;
- homepage returns 2xx and renders the expected release;
- production error/latency alerts remain below rollback thresholds during the observation window.

The local equivalent is:

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke-local.ps1 -IncludeWeb -Attempts 30
```

## Rollback

Rollback is a **tag/digest selection operation**, not a rebuild.

1. Identify the last known-good tagged release and its retained `deployment-manifest.json`.
2. Dispatch **Promote immutable release** for the affected environment using that previous release version.
3. Let the normal environment approval, release-manifest, tag-binding and signature checks execute again.
4. Deploy the pinned digests through the provider adapter.
5. Run the smoke criteria again and record the incident/change reference.

If a database migration is not backward compatible with the previous backend image, do not blindly roll the application back. Follow the migration-specific recovery plan. Flyway migrations in this repository are forward-only; destructive database rollback requires an explicit incident decision and restored data validation.

## Evidence to retain

For a portfolio/release record retain the Git tag, `release-manifest.json`, `release-manifest.json.sha256`, deployment manifest, SBOMs, release/promotion workflow URLs, smoke output and (for production) change/approval record. The repository also keeps `infra/release/release-manifest.schema.json` and `infra/release/deployment-manifest.schema.json` as versioned artifact-shape contracts. Together these prove what was built, what exact bytes were authorized and which approval path promoted them.
