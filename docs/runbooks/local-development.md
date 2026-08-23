# Local development runbook

## Start infrastructure

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f infra/compose.yaml up -d
docker compose --env-file .env -f infra/compose.yaml ps
```

## Backend

```powershell
Set-Location backend
$env:DB_URL = "jdbc:postgresql://localhost:5432/cinnamon_clay"
$env:DB_USER = "cinnamon_clay"
$env:DB_PASSWORD = "change-me-locally"
mvn spring-boot:run
```

## Public web

```powershell
Set-Location public-web
npm install
$env:BACKEND_INTERNAL_URL = "http://localhost:8080"
npm run dev
```

Commit the generated `package-lock.json`.

## Flutter admin

Generate and configure the Android runner once from a clean working tree:

```powershell
Set-Location admin-flutter
powershell -ExecutionPolicy Bypass -File tool/bootstrap_android.ps1
```

Start an Android emulator/device, then map its loopback ports to the host services:

```powershell
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8081 tcp:8081
```

Run the application:

```powershell
flutter run `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay `
  --dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile `
  --dart-define=OIDC_ALLOW_INSECURE=true
```

Review and commit the generated `android/` runner instead of regenerating it for every session. See `docs/runbooks/admin-oidc-local.md`.

## Stop

```powershell
docker compose --env-file .env -f infra/compose.yaml down
```

Do not add `-v` unless you intentionally want to delete the local PostgreSQL volume.
