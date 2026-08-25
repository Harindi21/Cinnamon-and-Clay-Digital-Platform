from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from release_manifest import ManifestError, resolve_release_manifest  # noqa: E402


class ReleaseManifestTest(unittest.TestCase):
    def valid_manifest(self) -> dict[str, object]:
        return {
            "schemaVersion": "1",
            "releaseVersion": "1.2.3-rc.1",
            "source": {
                "repository": "Harindi21/Cinnamon-and-Clay-Digital-Platform",
                "revision": "a" * 40,
            },
            "images": {
                "backend": {
                    "ref": "ghcr.io/harindi21/cinnamon-clay-backend",
                    "digest": "sha256:" + "b" * 64,
                    "sbom": "backend.cdx.json",
                },
                "publicWeb": {
                    "ref": "ghcr.io/harindi21/cinnamon-clay-public-web",
                    "digest": "sha256:" + "c" * 64,
                    "sbom": "public-web.cdx.json",
                },
            },
            "generatedAt": "2026-08-25T00:00:00+00:00",
        }

    def write_manifest(self, payload: dict[str, object]) -> Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "release-manifest.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_accepts_repository_owned_release(self) -> None:
        path = self.write_manifest(self.valid_manifest())
        resolved = resolve_release_manifest(
            path,
            expected_release_version="1.2.3-rc.1",
            expected_repository="Harindi21/Cinnamon-and-Clay-Digital-Platform",
            expected_source_revision="a" * 40,
        )

        self.assertEqual(
            resolved.backend_ref,
            "ghcr.io/harindi21/cinnamon-clay-backend",
        )
        self.assertEqual(len(resolved.manifest_sha256), 64)

    def test_rejects_requested_version_mismatch(self) -> None:
        path = self.write_manifest(self.valid_manifest())
        with self.assertRaisesRegex(ManifestError, "does not match requested version"):
            resolve_release_manifest(path, expected_release_version="1.2.4")

    def test_rejects_tag_revision_mismatch(self) -> None:
        path = self.write_manifest(self.valid_manifest())
        with self.assertRaisesRegex(ManifestError, "does not match tag revision"):
            resolve_release_manifest(path, expected_source_revision="d" * 40)

    def test_rejects_cross_repository_image_reference(self) -> None:
        payload = self.valid_manifest()
        payload["images"]["backend"]["ref"] = "ghcr.io/other/cinnamon-clay-backend"  # type: ignore[index]
        path = self.write_manifest(payload)

        with self.assertRaisesRegex(ManifestError, "images.backend.ref must be"):
            resolve_release_manifest(path)

    def test_rejects_malformed_digest(self) -> None:
        payload = self.valid_manifest()
        payload["images"]["publicWeb"]["digest"] = "latest"  # type: ignore[index]
        path = self.write_manifest(payload)

        with self.assertRaisesRegex(ManifestError, "images.publicWeb.digest"):
            resolve_release_manifest(path)

    def test_rejects_wrong_sbom_asset_name(self) -> None:
        payload = self.valid_manifest()
        payload["images"]["backend"]["sbom"] = "renamed.json"  # type: ignore[index]
        path = self.write_manifest(payload)

        with self.assertRaisesRegex(ManifestError, "images.backend.sbom must be"):
            resolve_release_manifest(path)

    def test_rejects_unversioned_extra_fields(self) -> None:
        payload = self.valid_manifest()
        payload["mutableTag"] = "latest"
        path = self.write_manifest(payload)

        with self.assertRaisesRegex(ManifestError, "unsupported keys: mutableTag"):
            resolve_release_manifest(path)

    def test_rejects_generated_time_without_timezone(self) -> None:
        payload = self.valid_manifest()
        payload["generatedAt"] = "2026-08-25T00:00:00"
        path = self.write_manifest(payload)

        with self.assertRaisesRegex(ManifestError, "must include a timezone offset"):
            resolve_release_manifest(path)


if __name__ == "__main__":
    unittest.main()
