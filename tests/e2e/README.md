# Public-web browser E2E

These tests exercise the built Next.js application in a real Chromium browser while a deterministic Python mock provides the public backend contract. This deliberately separates customer-browser regressions from PostgreSQL/Keycloak/MinIO setup; the Spring integration suite remains responsible for backend persistence and authorization behavior.

## Local run

From the repository root, create a Python virtual environment, install the pinned test dependencies, and install Chromium:

```powershell
python -m venv .local/e2e-venv
.local/e2e-venv/Scripts/python -m pip install -r tests/e2e/requirements.txt
.local/e2e-venv/Scripts/python -m playwright install chromium
```

Build the web application:

```powershell
Set-Location public-web
npm ci
npm run build
Set-Location ..
```

Start the deterministic backend in terminal 1:

```powershell
.local/e2e-venv/Scripts/python tests/e2e/mock_backend.py
```

Start the built Next.js application in terminal 2:

```powershell
$env:BACKEND_INTERNAL_URL='http://127.0.0.1:18082'
$env:PUBLIC_REVALIDATION_SECRET='e2e-only-secret'
Set-Location public-web
npm start -- --hostname 127.0.0.1 --port 3000
```

Run the suite in terminal 3:

```powershell
.local/e2e-venv/Scripts/python -m pytest tests/e2e -q
```

The CI job additionally runs Lighthouse against the same built application and stores the report as a workflow artifact.
