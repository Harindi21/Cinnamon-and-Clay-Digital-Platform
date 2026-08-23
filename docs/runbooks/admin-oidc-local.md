# Local admin OIDC runbook

The Flutter administrator application authenticates with the local Keycloak realm through the Authorization Code flow with PKCE.

## Prerequisites

Start local infrastructure from the repository root:

```powershell
docker compose --env-file .env -f infra/compose.yaml up -d
```

Start the backend with the local OIDC configuration:

```powershell
Set-Location backend

$env:DB_URL = "jdbc:postgresql://localhost:5432/cinnamon_clay"
$env:DB_USER = "cinnamon_clay"
$env:DB_PASSWORD = "change-me-locally"
$env:OIDC_ISSUER_URI = "http://localhost:8081/realms/cinnamon-clay"
$env:OIDC_AUDIENCE = "cinnamon-clay-api"
$env:OIDC_RESOURCE_CLIENT_ID = "cinnamon-clay-api"

mvn spring-boot:run
```

Verify OIDC discovery:

```powershell
Invoke-RestMethod `
  http://localhost:8081/realms/cinnamon-clay/.well-known/openid-configuration |
  Select-Object issuer
```

## Generate and configure Android

Commit the Dart authentication changes before running the bootstrap because the script uses Git to preserve repository-owned source files.

From `admin-flutter`:

```powershell
powershell -ExecutionPolicy Bypass -File tool/bootstrap_android.ps1
```

The script creates `android/` with package namespace `dev.cinnamonandclay.cinnamon_clay_admin` and applies the required native security configuration.

The resulting native configuration should include:

```kotlin
minSdk = 23

manifestPlaceholders.putAll(
    mapOf(
        "appAuthRedirectScheme" to "dev.cinnamonandclay.admin"
    )
)
```

The redirect URI registered in Keycloak is:

```text
dev.cinnamonandclay.admin:/oauthredirect
```

The scheme must remain lowercase.

The main Android manifest disables application backup. This prevents encrypted secure-storage preferences from being restored to a device without the matching Android Keystore key.

The debug manifest alone enables cleartext traffic so local Docker services can use HTTP. Do not enable cleartext traffic in the release manifest. Production OIDC and API endpoints must use HTTPS.

## Route emulator localhost to the development machine

When using an Android emulator or a USB-connected Android device with ADB, run:

```powershell
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8081 tcp:8081
```

This lets the app use the same `localhost` issuer that the Spring resource server validates.

## Run the admin app

```powershell
Set-Location admin-flutter

flutter run `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay `
  --dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile `
  --dart-define=OIDC_ALLOW_INSECURE=true
```

`OIDC_ALLOW_INSECURE=true` is required only for local HTTP development. Its application default is `false`.

Use one of the local Keycloak users provisioned by `infra/keycloak/cinnamon-clay-realm.json`.

## Expected flow

1. The app opens in the signed-out state.
2. Tapping **Sign in** opens the system browser.
3. Keycloak authenticates the user and returns through the custom URI scheme.
4. AppAuth exchanges the authorization code using PKCE.
5. Tokens are stored in platform secure storage.
6. The app calls `GET /api/v1/admin/me` with the bearer token.
7. Spring validates issuer, signature, lifetime, audience and roles.
8. Authorized users reach the admin catalog.
9. Access tokens are refreshed before expiry when a refresh token is available.
10. Sign-out clears local secure storage even if remote browser logout cannot complete.

## Verification before commit

```powershell
flutter analyze
flutter test
```

Review the native changes before committing:

```powershell
git status
git diff -- admin-flutter/android admin-flutter/pubspec.lock
```

Do not commit access tokens, refresh tokens, `.env`, emulator data or Keycloak local credentials.

## iOS

The Dart authentication code is compatible with iOS, but the native iOS runner should be generated and configured on a macOS development environment. Register `dev.cinnamonandclay.admin` in `CFBundleURLTypes` and configure Keychain Sharing before treating iOS as a supported release target.
