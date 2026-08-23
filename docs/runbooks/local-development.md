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

Generate platform folders once:

```powershell
Set-Location admin-flutter
flutter create --platforms=windows,android,web --project-name cinnamon_clay_admin .
```

Restore repository-owned source files if `flutter create` replaced them, then:

```powershell
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

## Stop

```powershell
docker compose --env-file .env -f infra/compose.yaml down
```

Do not add `-v` unless you intentionally want to delete the local PostgreSQL volume.
