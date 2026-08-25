# Cinnamon & Clay admin

The Flutter administrator application is the staff-facing control plane for the platform. It uses OIDC Authorization Code + PKCE for authentication and the Spring API for all authorization and persistence decisions.

Administrator workspaces cover:

- catalog/menu management;
- site content, contact details, hours and social links;
- media upload, replacement, placement, gallery ordering, hide/reactivate and object-storage maintenance;
- review moderation;
- administrator-only, read-only audit history with actor, action, resource, request/trace IDs and before/after state.

The application uses `flutter_appauth` for browser-based OIDC + PKCE, `flutter_secure_storage` for token storage, Riverpod for session/application state, Dio for authenticated APIs, and `file_selector` for native image selection. Every API request also carries a bounded `X-Request-Id` so user-visible failures can be correlated with backend logs and audit events.

## Android runner

`android/` is committed and reviewable production code. CI pins Flutter 3.47.1 instead of floating on the stable channel so native build evidence remains reproducible. The runner uses application ID `dev.cinnamonandclay.admin`, Android API 24+, the custom AppAuth redirect `dev.cinnamonandclay.admin:/oauthredirect`, debug-only cleartext networking, explicit backup exclusion and environment-only release signing. The Gradle distribution is pinned by version and SHA-256; Flutter's SDK injects its standard wrapper launcher/JAR when needed, so generated wrapper binaries do not create Git noise.

Do **not** run `flutter create` over the repository as part of normal setup. Restore `admin-flutter/android/` from Git if it is missing. The legacy `tool/bootstrap_android.ps1` entrypoint now delegates to the repository smoke verifier rather than regenerating native source.

Normal local development:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 admin
```

A stronger device/emulator smoke is available from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/admin-android-smoke.ps1
```

See `docs/runbooks/admin-oidc-local.md` and `docs/runbooks/admin-android-device-smoke.md`.

## Environment contract

Dart compile-time defines support three named environments: `local`, `staging`, and `production`. Non-local startup validation requires HTTPS API/OIDC endpoints and rejects `OIDC_ALLOW_INSECURE=true`. Release-mode startup also refuses an omitted environment or `APP_ENVIRONMENT=local`, preventing an accidentally signed local configuration from behaving like a production build.

Local development defaults are:

```text
APP_ENVIRONMENT=local
API_BASE_URL=http://localhost:8082
OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay
OIDC_CLIENT_ID=cinnamon-clay-admin-mobile
OIDC_REDIRECT_URL=dev.cinnamonandclay.admin:/oauthredirect
```

The debug Android manifest/network-security configuration is the only build variant that permits cleartext HTTP.

The Gradle distribution URL and SHA-256 are pinned in `android/gradle/wrapper/gradle-wrapper.properties`. The Flutter tool materializes its SDK-managed Gradle wrapper launcher/JAR during Android builds, so CI validates the committed pin before `flutter build` and does not invoke `gradlew` as a standalone preflight.

## Quality checks

```powershell
flutter pub get
.\tool\verify_gradle_wrapper_pin.ps1
flutter analyze
flutter test
flutter build apk --debug
```

CI also builds a release AAB with an ephemeral signing key to prove the signing path works, and a path-scoped emulator workflow launches the native application and verifies the AppAuth callback registration.

Production AABs are built through `.github/workflows/android-release.yml` using the protected `mobile-release` GitHub Environment. The workflow emits a versioned signed AAB, SHA-256, signer-verification output, a `cinnamon-clay-admin-<version>-<build-number>.release.json` manifest, and a GitHub/Sigstore build-provenance attestation. See `docs/runbooks/admin-android-release.md`.

The application does not contain a password form and does not store administrator passwords. Authentication is delegated to the configured OIDC provider; authorization remains enforced by the Spring API. The audit workspace is intentionally administrator-only even though editors can perform ordinary content operations.
