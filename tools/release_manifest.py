#!/usr/bin/env python3
"""Validate Cinnamon & Clay release manifests without third-party dependencies."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
REVISION = re.compile(r"^[0-9a-f]{40}$")
DIGEST = re.compile(r"^sha256:[0-9a-f]{64}$")
REPOSITORY = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SAFE_ASSET = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")


class ManifestError(ValueError):
    """Raised when a release manifest violates the repository contract."""


@dataclass(frozen=True)
class ResolvedRelease:
    release_version: str
    repository: str
    source_revision: str
    backend_ref: str
    backend_digest: str
    public_web_ref: str
    public_web_digest: str
    manifest_sha256: str


def _require_mapping(value: Any, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ManifestError(f"{path} must be an object.")
    return value


def _require_string(value: Any, path: str) -> str:
    if not isinstance(value, str) or not value:
        raise ManifestError(f"{path} must be a non-empty string.")
    return value


def _require_match(value: str, pattern: re.Pattern[str], path: str) -> None:
    if pattern.fullmatch(value) is None:
        raise ManifestError(f"{path} has an invalid value: {value!r}")


def _require_exact_keys(data: dict[str, Any], path: str, expected: set[str]) -> None:
    actual = set(data)
    missing = sorted(expected - actual)
    unexpected = sorted(actual - expected)
    if missing:
        raise ManifestError(f"{path} is missing required keys: {', '.join(missing)}.")
    if unexpected:
        raise ManifestError(f"{path} contains unsupported keys: {', '.join(unexpected)}.")


def _require_datetime(value: Any, path: str) -> str:
    text = _require_string(value, path)
    try:
        parsed = datetime.fromisoformat(text.replace('Z', '+00:00'))
    except ValueError as exc:
        raise ManifestError(f"{path} must be an ISO-8601 date-time.") from exc
    if parsed.tzinfo is None:
        raise ManifestError(f"{path} must include a timezone offset.")
    return text


def _validate_image(
    image: Any,
    *,
    name: str,
    expected_ref: str,
    expected_sbom: str,
) -> tuple[str, str]:
    data = _require_mapping(image, f"images.{name}")
    _require_exact_keys(data, f"images.{name}", {"ref", "digest", "sbom"})
    ref = _require_string(data.get("ref"), f"images.{name}.ref")
    digest = _require_string(data.get("digest"), f"images.{name}.digest")
    sbom = _require_string(data.get("sbom"), f"images.{name}.sbom")

    if ref != expected_ref:
        raise ManifestError(
            f"images.{name}.ref must be {expected_ref!r}; received {ref!r}."
        )
    _require_match(digest, DIGEST, f"images.{name}.digest")
    _require_match(sbom, SAFE_ASSET, f"images.{name}.sbom")
    if sbom != expected_sbom:
        raise ManifestError(
            f"images.{name}.sbom must be {expected_sbom!r}; received {sbom!r}."
        )
    return ref, digest


def resolve_release_manifest(
    manifest_path: Path,
    *,
    expected_release_version: str | None = None,
    expected_repository: str | None = None,
    expected_source_revision: str | None = None,
) -> ResolvedRelease:
    try:
        raw = manifest_path.read_bytes()
    except OSError as exc:
        raise ManifestError(f"Unable to read manifest {manifest_path}: {exc}") from exc

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ManifestError(f"Manifest is not valid JSON: {exc}") from exc

    root = _require_mapping(payload, "manifest")
    _require_exact_keys(
        root,
        "manifest",
        {"schemaVersion", "releaseVersion", "source", "images", "generatedAt"},
    )
    if root.get("schemaVersion") != "1":
        raise ManifestError(
            f"schemaVersion must be '1'; received {root.get('schemaVersion')!r}."
        )

    release_version = _require_string(root.get("releaseVersion"), "releaseVersion")
    _require_match(release_version, SEMVER, "releaseVersion")
    if expected_release_version is not None and release_version != expected_release_version:
        raise ManifestError(
            f"releaseVersion {release_version!r} does not match requested "
            f"version {expected_release_version!r}."
        )

    source = _require_mapping(root.get("source"), "source")
    _require_exact_keys(source, "source", {"repository", "revision"})
    repository = _require_string(source.get("repository"), "source.repository")
    revision = _require_string(source.get("revision"), "source.revision")
    _require_match(repository, REPOSITORY, "source.repository")
    _require_match(revision, REVISION, "source.revision")

    if expected_repository is not None and repository != expected_repository:
        raise ManifestError(
            f"source.repository {repository!r} does not match expected "
            f"repository {expected_repository!r}."
        )
    if expected_source_revision is not None and revision != expected_source_revision:
        raise ManifestError(
            f"source.revision {revision!r} does not match tag revision "
            f"{expected_source_revision!r}."
        )

    _require_datetime(root.get("generatedAt"), "generatedAt")

    owner = repository.split("/", 1)[0].lower()
    images = _require_mapping(root.get("images"), "images")
    _require_exact_keys(images, "images", {"backend", "publicWeb"})
    backend_ref, backend_digest = _validate_image(
        images.get("backend"),
        name="backend",
        expected_ref=f"ghcr.io/{owner}/cinnamon-clay-backend",
        expected_sbom="backend.cdx.json",
    )
    public_web_ref, public_web_digest = _validate_image(
        images.get("publicWeb"),
        name="publicWeb",
        expected_ref=f"ghcr.io/{owner}/cinnamon-clay-public-web",
        expected_sbom="public-web.cdx.json",
    )

    return ResolvedRelease(
        release_version=release_version,
        repository=repository,
        source_revision=revision,
        backend_ref=backend_ref,
        backend_digest=backend_digest,
        public_web_ref=public_web_ref,
        public_web_digest=public_web_digest,
        manifest_sha256=hashlib.sha256(raw).hexdigest(),
    )


def _append_github_output(path: Path, release: ResolvedRelease) -> None:
    values = {
        "release_version": release.release_version,
        "source_revision": release.source_revision,
        "backend_ref": release.backend_ref,
        "backend_digest": release.backend_digest,
        "public_web_ref": release.public_web_ref,
        "public_web_digest": release.public_web_digest,
        "release_manifest_sha256": release.manifest_sha256,
    }
    with path.open("a", encoding="utf-8", newline="\n") as stream:
        for key, value in values.items():
            stream.write(f"{key}={value}\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--release-version")
    parser.add_argument("--repository")
    parser.add_argument("--source-revision")
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()

    try:
        release = resolve_release_manifest(
            args.manifest,
            expected_release_version=args.release_version,
            expected_repository=args.repository,
            expected_source_revision=args.source_revision,
        )
    except ManifestError as exc:
        parser.exit(1, f"release manifest validation failed: {exc}\n")

    if args.github_output is not None:
        _append_github_output(args.github_output, release)

    print(
        "[PASS] release manifest "
        f"{release.release_version} -> "
        f"{release.backend_ref}@{release.backend_digest}, "
        f"{release.public_web_ref}@{release.public_web_digest}"
    )
    print(f"[PASS] manifest sha256={release.manifest_sha256}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
