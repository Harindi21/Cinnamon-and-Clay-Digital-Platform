# Release, promotion and rollback runbook

## Purpose

This runbook defines the provider-neutral release boundary. It distinguishes image creation from environment authorization and keeps rollback coordinates immutable.

## Create a release candidate

Preferred path: push an annotated SemVer tag from a commit on `main`, for example `v1.0.0-rc.1`. The **Release** workflow reruns source verification, builds backend/public-web images, publishes to GHCR, scans them, emits CycloneDX SBOMs, records BuildKit provenance/SBOM attestations and keyless-signs each digest with Cosign.

For rehearsal without a Git tag, dispatch **Release** manually with a SemVer value. Manual runs publish the same signed image artifacts but do not create a GitHub Release.

The important output is `release-manifest.json`. Tags are convenient discovery labels; digests are the deployment identity.

## Verify locally

Download `release-manifest.json` from the workflow/GitHub Release and run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-release-manifest.ps1 `
  -ManifestPath .\release-manifest.json
```

With Cosign installed and registry access configured:

```powershell
powershell -ExecutionPolicy Bypass -File tools/verify-release-manifest.ps1 `
  -ManifestPath .\release-manifest.json `
  -VerifySignatures
```

## Promote

1. Configure GitHub Environments named `staging` and `production`; production should require a reviewer.
2. Open **Actions → Promote immutable release → Run workflow**.
3. Choose the target environment.
4. Copy `releaseVersion`, `source.revision`, backend digest and public-web digest exactly from the release manifest.
5. Approve the GitHub Environment gate when appropriate.
6. The workflow verifies both signatures and registry objects, then emits `deployment-manifest.json`.
7. The provider deployment adapter must deploy the two `ref@sha256:digest` values from that manifest and then run an environment smoke check.

No build occurs during promotion.

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

Rollback is a **digest selection operation**, not a rebuild.

1. Identify the last known-good `deployment-manifest.json` or release manifest.
2. Dispatch **Promote immutable release** for the affected environment using that previous release version, source revision and backend/public-web digests.
3. Let the normal environment approval/signature checks execute.
4. Deploy those pinned digests through the provider adapter.
5. Run the smoke criteria again and record the incident/change reference.

If a database migration is not backward compatible with the previous backend image, do not blindly roll the application back. Follow the migration-specific recovery plan. Flyway migrations in this repository are forward-only; destructive database rollback requires an explicit incident decision and restored data validation.

## Evidence to retain

For a portfolio/release record retain the Git tag, release manifest, deployment manifest, SBOMs, workflow URL, smoke output and (for production) change/approval record. These prove what was built and what exact bytes were authorized.
