# Cinnamon & Clay admin

The Flutter administrator application is the staff-facing control plane for the platform. It uses OIDC Authorization Code + PKCE for authentication and the Spring API for all authorization and persistence decisions.

Current administrator workspaces cover:

- catalog/menu management;
- site content, contact details, hours and social links;
- media upload, replacement, placement, hide/reactivate and object-storage maintenance;
- review moderation;
- administrator-only, read-only audit history with actor, action, resource, request/trace IDs and before/after state.

The application uses `flutter_appauth` for browser-based OIDC + PKCE, `flutter_secure_storage` for token storage, Riverpod for session/application state, Dio for authenticated APIs, and `file_selector` for native image selection. Every API request also carries a bounded `X-Request-Id` so user-visible failures can be correlated with backend logs and audit events.

## Local Android setup

The repository intentionally keeps native runner generation explicit so it is produced by the team's installed Flutter SDK and reviewed as native production code. From the repository root:

```powershell
Set-Location admin-flutter
powershell -ExecutionPolicy Bypass -File tool/bootstrap_android.ps1
```

The script generates the Android platform, preserves repository-owned Dart source, sets Android API 23 for secure storage, registers the AppAuth redirect scheme, disables Android application backup for auth storage, enables cleartext traffic only in the debug manifest, and runs `flutter pub get`.

Once reviewed, commit `admin-flutter/android/`. The same runner hosts the native media file selector.

For normal local development after that, the root helper configures ADB port reversal and all Dart defines from `.env`:

```powershell
./tools/dev.ps1 admin
```

See `docs/runbooks/admin-oidc-local.md` and `docs/runbooks/local-development.md` for the complete flow.

## Quality checks

```powershell
flutter pub get
flutter analyze
flutter test
```

The application does not contain a password form and does not store administrator passwords. Authentication is delegated to the configured OIDC provider; authorization remains enforced by the Spring API. The audit workspace is intentionally administrator-only even though editors can perform ordinary content operations.
