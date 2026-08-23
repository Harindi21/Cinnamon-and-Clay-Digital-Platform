# Cinnamon & Clay admin

The Flutter administrator application uses OIDC Authorization Code + PKCE for staff authentication and the Spring API for authorization.

The authentication layer uses:

- `flutter_appauth` for browser-based OIDC and PKCE;
- `flutter_secure_storage` for access, refresh and ID token storage;
- Riverpod for asynchronous session state;
- Dio for public and authenticated API clients.

## Local Android setup

After applying the authentication source changes, commit them first. Then generate and configure the Android platform from the repository root:

```powershell
Set-Location admin-flutter
powershell -ExecutionPolicy Bypass -File tool/bootstrap_android.ps1
```

The script:

1. generates the Android Flutter platform;
2. preserves the repository-owned Dart source;
3. sets Android API 23 for secure storage;
4. registers the AppAuth redirect scheme;
5. disables Android application backup for auth storage;
6. enables cleartext traffic only in the debug manifest;
7. runs `flutter pub get`.

The generated `android/` directory is part of the application once authentication is introduced and should be reviewed and committed. Native redirect/security configuration is production code, not disposable local scaffolding.

Follow:

```text
docs/runbooks/admin-oidc-local.md
```

for infrastructure, ADB port reversal, run arguments and expected authentication behavior.

## Quality checks

```powershell
flutter pub get
flutter analyze
flutter test
```

The application does not contain a password form and does not store administrator passwords. Authentication is delegated to the configured OIDC provider; authorization remains enforced by the Spring API.
