# Local development runbook

The checked-in local defaults intentionally avoid common workstation conflicts:

- PostgreSQL host port `55432` instead of `5432`;
- Spring Boot `8082` instead of `8080`;
- Keycloak `8081`;
- Next.js `3000`;
- MinIO `9000` / console `9001`.

All values remain overrideable in `.env`.

## First-time environment

```powershell
Copy-Item .env.example .env
```

Review `.env`; local placeholder secrets must not be reused in real environments.

## Terminal 1 - infrastructure

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up
```

To include Prometheus and Grafana:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-up -Observability
```

Check ports/containers:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 status
```

## Terminal 2 - backend

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 backend
```

The launcher reads `.env` and exports the Spring datasource/OIDC/media/cache variables for the process, avoiding manual `set DB_*` drift.

Verify:

```powershell
Invoke-RestMethod http://localhost:8082/actuator/health
Invoke-RestMethod http://localhost:8082/api/v1/catalog/menu
```

## Terminal 3 - public web

Install once:

```powershell
Set-Location public-web
npm ci
Set-Location ..
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 web
```

Open `http://localhost:3000`.

The launcher passes `BACKEND_INTERNAL_URL=http://127.0.0.1:8082`, so Next.js does not accidentally call a workstation service on port 8080.

## Terminal 4 - Flutter admin

The Android runner is committed. Start an emulator/device, then:

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 admin
```

The launcher configures `adb reverse` for backend `8082` and Keycloak `8081`, then supplies the local OIDC/API `dart-define` values.

After native/auth changes, run the stronger device smoke:

```powershell
powershell -ExecutionPolicy Bypass -File tools/admin-android-smoke.ps1
```

See `docs/runbooks/admin-oidc-local.md` and `docs/runbooks/admin-android-device-smoke.md`.

## Smoke the local stack

After the backend is running, verify infrastructure plus all public API reads. Add `-IncludeWeb` after Next.js starts and `-Observability` when that profile is enabled:

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke-local.ps1 -IncludeWeb
```

The smoke script checks backend health, all five public API capabilities, Keycloak discovery, MinIO health and optionally the public web/observability endpoints. It intentionally does not automate administrator credentials or token issuance.

## Stop infrastructure

```powershell
powershell -ExecutionPolicy Bypass -File tools/dev.ps1 infra-down
```

Do not use Docker Compose `down -v` unless you intentionally want to delete local PostgreSQL/MinIO data.

## Backups

See `docs/runbooks/database-backup-restore.md` for executable backup, restore and restore-rehearsal commands.

## Optional demo gallery content

After infrastructure, backend and Flutter are running, restore the original static prototype's remote demo imagery into an ignored local folder:

```powershell
powershell -ExecutionPolicy Bypass -File tools/prepare-demo-media.ps1
```

Then use **Media → Gallery → Upload batch** in the admin app. See `docs/runbooks/admin-media-management.md` for metadata and scripted-upload guidance.
