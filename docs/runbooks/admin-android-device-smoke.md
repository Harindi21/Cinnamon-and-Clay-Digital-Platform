# Android device and OIDC smoke runbook

Use this after Android/auth changes and before capturing portfolio release evidence.

## Prerequisites

Start the local infrastructure and backend using the normal development helpers:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 backend
```

Start an Android emulator or connect a USB-debuggable device. Confirm it appears as `device`:

```powershell
adb devices
```

## Automated native smoke

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/admin-android-smoke.ps1
```

If multiple devices are attached:

```powershell
powershell -ExecutionPolicy Bypass -File tools/admin-android-smoke.ps1 `
  -DeviceId emulator-5554
```

The script:

1. waits for backend readiness and Keycloak OIDC discovery on the host;
2. runs `adb reverse` for backend `8082` and Keycloak `8081`;
3. resolves Flutter packages and optionally runs analyze/unit tests;
4. builds and installs the debug APK;
5. verifies Android resolves `dev.cinnamonandclay.admin:/oauthredirect` to AppAuth;
6. runs the Flutter integration launch smoke on the real emulator/device;
7. launches the installed administration app.

Use `-SkipServicePreflight` only when intentionally testing native packaging without the local services.

## Human OIDC verification

The system browser is intentionally outside Flutter's widget automation boundary. Complete this short real-flow check manually:

1. Tap **Sign in**.
2. Confirm Chrome/system browser opens the local Keycloak login page.
3. Authenticate with one of the local users provisioned by `infra/keycloak/cinnamon-clay-realm.json`.
4. Confirm the browser returns to Cinnamon & Clay Admin through `dev.cinnamonandclay.admin:/oauthredirect`.
5. Confirm the Catalog screen loads authenticated data from the Spring API.
6. Navigate to Site, Media and Reviews to prove bearer-token calls continue to work.
7. Sign out and confirm the application returns to the signed-out screen.

For portfolio evidence, capture the signed-out screen, browser/Keycloak step without exposing credentials, authenticated admin shell and the successful command output from `admin-android-smoke.ps1`.
