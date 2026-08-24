# Local admin OIDC runbook

The Flutter administrator application authenticates with the local Keycloak realm through Authorization Code + PKCE. The Android runner is committed under `admin-flutter/android/`; normal development does not regenerate platform files.

## Prerequisites

Start infrastructure:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up
```

Start the backend in another terminal:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 backend
```

Verify the backend and OIDC discovery:

```powershell
Invoke-RestMethod http://localhost:8082/actuator/health
Invoke-RestMethod `
  http://localhost:8081/realms/cinnamon-clay/.well-known/openid-configuration |
  Select-Object issuer
```

## Native OIDC contract

The committed Android configuration uses:

```text
applicationId: dev.cinnamonandclay.admin
minimum Android: API 24
redirect URI: dev.cinnamonandclay.admin:/oauthredirect
OIDC client: cinnamon-clay-admin-mobile
```

The same redirect URI is registered in `infra/keycloak/cinnamon-clay-realm.json`. The custom scheme must remain lowercase.

The main/release Android application denies cleartext traffic and disables backup. A debug-only manifest and network-security resource permit HTTP for the local backend and Keycloak. Production API and issuer endpoints must use HTTPS.

## Route loopback ports to the workstation

The Android emulator/device cannot normally reach workstation `localhost`. `tools/dev.ps1 admin` and `tools/admin-android-smoke.ps1` configure:

```powershell
adb reverse tcp:8082 tcp:8082
adb reverse tcp:8081 tcp:8081
```

Using `localhost` in the mobile issuer is intentional: it keeps the issuer value identical to the Keycloak URL the Spring resource server validates.

## Run the admin application

Preferred:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 admin
```

Equivalent Flutter invocation from `admin-flutter`:

```powershell
flutter run `
  --dart-define=APP_ENVIRONMENT=local `
  --dart-define=API_BASE_URL=http://localhost:8082 `
  --dart-define=OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay `
  --dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile `
  --dart-define=OIDC_ALLOW_INSECURE=true
```

Use one of the local Keycloak users provisioned by `infra/keycloak/cinnamon-clay-realm.json`.

## Expected flow

1. The app opens in the signed-out state.
2. **Sign in** opens the system browser.
3. Keycloak authenticates the user and redirects to `dev.cinnamonandclay.admin:/oauthredirect`.
4. AppAuth exchanges the authorization code using PKCE.
5. Tokens are stored in platform secure storage.
6. The app calls `GET /api/v1/admin/me` with the bearer token.
7. Spring validates issuer, signature, lifetime, audience and roles.
8. Authorized users reach the admin workspace.
9. Access tokens are refreshed before expiry when a refresh token is available.
10. Sign-out clears local secure storage even if remote browser logout cannot complete.

## Stronger device verification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/admin-android-smoke.ps1
```

This builds/installs the APK, checks the AppAuth callback registration, runs the Flutter integration smoke and launches the app. Complete the external-browser login manually afterward; see `docs/runbooks/admin-android-device-smoke.md`.

## Production safety

`APP_ENVIRONMENT=staging` and `production` fail fast when either API/OIDC endpoint is not HTTPS or when `OIDC_ALLOW_INSECURE=true`.

Release tasks additionally require signing values in the process environment. Production signing secrets belong in the protected `mobile-release` GitHub Environment; see `docs/runbooks/admin-android-release.md`.

Do not commit access tokens, refresh tokens, `.env`, emulator data, Keycloak local credentials or Android keystores.

## iOS

The Dart authentication code remains compatible with iOS, but iOS is not declared a supported repository target until its runner is generated/configured on macOS and receives equivalent Keychain and URL-scheme review.
