# ADR 0016: Build once and promote immutable container digests

- Status: Accepted
- Date: 2026-08-24

## Context

CI already verifies source and the repository contains non-root Dockerfiles, but a production release needs stronger evidence than a mutable image tag. Rebuilding for each environment can produce different bytes from the same source, mutable tags are weak rollback coordinates, and a container without provenance/SBOM/signature evidence is difficult to audit.

The portfolio also needs to demonstrate the separation between **building an artifact** and **authorizing that exact artifact for an environment** even though the final hosting provider is intentionally not hard-coded into this repository.

## Decision

1. Release builds run only after source-level quality gates pass.
2. Backend and public-web images are published to GHCR and identified by their `sha256` digest.
3. BuildKit emits provenance and SBOM attestations during image creation.
4. Trivy blocks release publication for fixed HIGH/CRITICAL vulnerabilities according to the repository security policy and emits CycloneDX SBOM artifacts.
5. GitHub OIDC is used for keyless Cosign signing; no long-lived signing key is stored in repository secrets.
6. The release workflow emits a machine-readable manifest containing source revision, release version, image references, immutable digests and SBOM filenames. The release/deployment artifact shapes are documented with JSON Schemas, while a standard-library validator enforces semantic trust constraints that JSON Schema cannot express across fields. Tagged releases publish the manifest plus a SHA-256 checksum as GitHub Release assets.
7. A tag-triggered release is accepted only when its commit is reachable from `main`; manual non-tag runs remain available for pipeline rehearsal.
8. Environment promotion is a separate manually dispatched workflow protected by GitHub Environments. Operators provide only the target environment and tagged release version; the workflow downloads the published release manifest instead of accepting hand-copied digests or source revisions.
9. Promotion verifies that the tag remains reachable from `main`, the manifest version matches the requested tag, the manifest source revision is the commit resolved by that tag, the image references belong to this repository owner, the manifest checksum matches and both image signatures were issued by the release workflow **for that exact tag**.
10. Manual non-tag release runs remain useful for release-pipeline rehearsal, but only published tagged GitHub Releases are eligible for environment promotion.
11. Provider-specific deployment uses the deployment manifest digests, not mutable tags. Rollback means re-promoting/redeploying the last known-good tagged digest pair; images are not rebuilt during rollback.

## Consequences

- A release can be traced from Git tag/commit to release manifest, image digest, SBOM and tag-bound signature.
- Staging and production can consume the exact same bytes without an operator retyping digests.
- A tag outside `main`, a mismatched tag/source revision, a cross-repository image reference or a release-manifest checksum mismatch fails before an environment deployment manifest is emitted.
- GitHub Environment reviewers can be configured as the promotion approval boundary.
- The repository does not pretend to deploy to a cloud account that has not been selected/configured. A provider adapter remains a deployment integration task.
- Release jobs are deliberately more expensive than ordinary PR CI because image vulnerability scanning and signing happen at the release boundary.
