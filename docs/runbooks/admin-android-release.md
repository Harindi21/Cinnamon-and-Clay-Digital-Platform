# Android administrator release runbook

The Android administrator application is released separately from the backend/public-web containers because Play distribution has its own signing and store lifecycle.

## Repository guarantees

Pull-request CI verifies:

- Dart analysis and unit/widget tests;
- Android debug APK assembly;
- the packaged `flutter_appauth` callback for `dev.cinnamonandclay.admin:/oauthredirect`;
- a release AAB build using an ephemeral CI keystore;
- JAR signature verification of that AAB using the generated signing certificate.

`Android device smoke` additionally boots an emulator when native/admin files change, launches the app and verifies that Android resolves the OIDC callback to AppAuth's redirect receiver.

## Configure the protected GitHub Environment

Create a GitHub Environment named `mobile-release`. Require reviewers for production use.

Environment variables:

- `ADMIN_API_BASE_URL` — production HTTPS Spring API origin;
- `ADMIN_OIDC_ISSUER_URL` — production HTTPS OIDC issuer.

Environment secrets:

- `ANDROID_KEYSTORE_BASE64` — base64-encoded upload keystore bytes;
- `ANDROID_KEYSTORE_PASSWORD`;
- `ANDROID_KEY_ALIAS`;
- `ANDROID_KEY_PASSWORD`.

The keystore must never be committed to Git. Keep the original in the organization's secret-management/backup system. Losing an upload key creates an operational recovery event even when Play App Signing is enabled.

## Build a release artifact

The backend/public-web release workflow should complete first so `v<version>` and its GitHub Release already exist.

Run **Actions → Android admin release → Run workflow** with:

- `version`: the existing platform release SemVer, for example `1.0.0`;
- `build_number`: a monotonically increasing Android version code.

The workflow checks out `v<version>`, runs Flutter quality gates, restores the keystore into the temporary runner directory, builds with:

```text
APP_ENVIRONMENT=production
OIDC_ALLOW_INSECURE=false
API_BASE_URL=<mobile-release environment variable>
OIDC_ISSUER_URL=<mobile-release environment variable>
OIDC_CLIENT_ID=cinnamon-clay-admin-mobile
```

It verifies the AAB signature, emits a SHA-256 checksum and signer report, writes a versioned release manifest, creates a GitHub/Sigstore build-provenance attestation for the AAB, uploads the evidence as a workflow artifact and attaches the release files to the existing GitHub Release. The evidence basename is `cinnamon-clay-admin-<version>-<build-number>`, so release assets are immutable and collision-visible rather than silently overwritten.

The mobile manifest records the platform version, Android build number, application ID, source revision, production API/issuer coordinates, callback URI and AAB digest. It is evidence metadata, not a deployment secret.

## Store promotion

Before Play Console upload:

1. compare `cinnamon-clay-admin-<version>-<build-number>.aab` with its adjacent `.aab.sha256` file;
2. run `gh attestation verify cinnamon-clay-admin-<version>-<build-number>.aab --repo <owner>/<repo>` and require the GitHub-hosted provenance verification to succeed;
3. review `cinnamon-clay-admin-<version>-<build-number>.release.json` and confirm its source revision matches the intended platform tag;
4. confirm the application ID is `dev.cinnamonandclay.admin`;
5. confirm the production Keycloak client allows `dev.cinnamonandclay.admin:/oauthredirect`;
6. verify the production API and issuer variables point to HTTPS endpoints;
7. promote through an internal testing track before wider distribution.

Store rollout is intentionally not automated by this repository until a real Play Console application/service-account boundary exists. Do not invent long-lived Google Play credentials solely to make the portfolio pipeline appear more automated.

## Rollback

Android clients cannot be remotely downgraded like server containers. Rollback means:

- halt/stage the current rollout in the store;
- promote the previous known-good version if store policy permits; or
- produce a forward-fix with a higher Android build number.

Backend compatibility should therefore remain at least one supported mobile version backward-compatible during normal rollout windows.
