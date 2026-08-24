param(
    [Parameter(Position = 0)]
    [ValidateSet('infra-up', 'infra-down', 'app-up', 'app-down', 'app-logs', 'backend', 'web', 'admin', 'status')]
    [string]$Command = 'status',

    [switch]$Observability
)

. (Join-Path $PSScriptRoot '_env.ps1')

$root = Get-RepositoryRoot
$envFile = Join-Path $root '.env'
Import-DotEnv -Path $envFile

$postgresPort = Get-EnvValue -Name 'POSTGRES_PORT' -Default '55432'
$backendPort = Get-EnvValue -Name 'BACKEND_PORT' -Default '8082'
$publicWebPort = Get-EnvValue -Name 'PUBLIC_WEB_PORT' -Default '3000'
$keycloakPort = Get-EnvValue -Name 'KEYCLOAK_PORT' -Default '8081'
$minioPort = Get-EnvValue -Name 'MINIO_API_PORT' -Default '9000'
$postgresDb = Get-EnvValue -Name 'POSTGRES_DB' -Default 'cinnamon_clay'
$postgresUser = Get-EnvValue -Name 'POSTGRES_USER' -Default 'cinnamon_clay'
$postgresPassword = Get-EnvValue -Name 'POSTGRES_PASSWORD' -Default 'change-me-locally'
$revalidationEnabled = Get-EnvValue -Name 'PUBLIC_REVALIDATION_ENABLED' -Default 'true'
$revalidationSecret = Get-EnvValue -Name 'PUBLIC_REVALIDATION_SECRET' -Default 'change-me-locally'

function Invoke-Compose {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    Assert-CommandAvailable -Name 'docker'
    Push-Location $root
    try {
        $base = @('compose', '--env-file', '.env', '-f', 'infra/compose.yaml')
        if ($Command -like 'app-*') {
            $base += @('--profile', 'app')
        }
        if ($Observability) {
            $base += @('--profile', 'observability')
        }
        & docker @base @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "docker compose exited with code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

switch ($Command) {
    'infra-up' {
        Invoke-Compose -Arguments @('up', '-d')
        Invoke-Compose -Arguments @('ps')
    }
    'infra-down' {
        Invoke-Compose -Arguments @('down')
    }
    'app-up' {
        Invoke-Compose -Arguments @('up', '-d', '--build')
        Invoke-Compose -Arguments @('ps')
        & (Join-Path $PSScriptRoot 'smoke-local.ps1') -IncludeWeb -Attempts 30 -RetryDelaySeconds 2
    }
    'app-down' {
        Invoke-Compose -Arguments @('down')
    }
    'app-logs' {
        Invoke-Compose -Arguments @('logs', '-f', 'backend', 'public-web')
    }
    'backend' {
        Assert-CommandAvailable -Name 'mvn'
        $env:DB_URL = "jdbc:postgresql://127.0.0.1:$postgresPort/$postgresDb"
        $env:DB_USER = $postgresUser
        $env:DB_PASSWORD = $postgresPassword
        $env:PORT = $backendPort
        $env:OIDC_ISSUER_URI = "http://localhost:$keycloakPort/realms/cinnamon-clay"
        $env:MEDIA_S3_ENDPOINT = "http://localhost:$minioPort"
        $env:PUBLIC_REVALIDATION_ENABLED = $revalidationEnabled
        $env:PUBLIC_REVALIDATION_URL = "http://localhost:$publicWebPort/api/internal/revalidate"
        $env:PUBLIC_REVALIDATION_SECRET = $revalidationSecret

        Write-Host "Starting backend on http://127.0.0.1:$backendPort"
        Write-Host "PostgreSQL: 127.0.0.1:$postgresPort/$postgresDb"
        Push-Location (Join-Path $root 'backend')
        try {
            & mvn spring-boot:run
            exit $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    }
    'web' {
        Assert-CommandAvailable -Name 'npm'
        $env:BACKEND_INTERNAL_URL = "http://127.0.0.1:$backendPort"
        $env:PUBLIC_REVALIDATION_SECRET = $revalidationSecret
        Write-Host "Starting public web on http://localhost:$publicWebPort"
        Write-Host "Backend: $env:BACKEND_INTERNAL_URL"
        Push-Location (Join-Path $root 'public-web')
        try {
            & npm run dev -- -p $publicWebPort
            exit $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    }
    'admin' {
        Assert-CommandAvailable -Name 'flutter'
        Assert-CommandAvailable -Name 'adb'
        $adminRoot = Join-Path $root 'admin-flutter'
        if (-not (Test-Path -LiteralPath (Join-Path $adminRoot 'android'))) {
            throw 'admin-flutter/android is missing. Restore the committed Android runner from Git, then retry.'
        }

        & adb reverse "tcp:$backendPort" "tcp:$backendPort"
        if ($LASTEXITCODE -ne 0) { throw 'adb reverse for the backend failed.' }
        & adb reverse "tcp:$keycloakPort" "tcp:$keycloakPort"
        if ($LASTEXITCODE -ne 0) { throw 'adb reverse for Keycloak failed.' }

        Push-Location $adminRoot
        try {
            & flutter run `
                '--dart-define=APP_ENVIRONMENT=local' `
                "--dart-define=API_BASE_URL=http://localhost:$backendPort" `
                "--dart-define=OIDC_ISSUER_URL=http://localhost:$keycloakPort/realms/cinnamon-clay" `
                '--dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile' `
                '--dart-define=OIDC_ALLOW_INSECURE=true'
            exit $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    }
    'status' {
        Invoke-Compose -Arguments @('ps')
        Write-Host ''
        Write-Host 'Local endpoints:'
        Write-Host "  Public web:     http://localhost:$publicWebPort"
        Write-Host "  Backend:        http://localhost:$backendPort"
        Write-Host "  Backend health: http://localhost:$backendPort/actuator/health"
        Write-Host "  Keycloak:       http://localhost:$keycloakPort"
        Write-Host "  PostgreSQL:     127.0.0.1:$postgresPort"
        Write-Host "  MinIO API:      http://localhost:$minioPort"
        Write-Host "  MinIO console:  http://localhost:$(Get-EnvValue -Name 'MINIO_CONSOLE_PORT' -Default '9001')"
        if ($Observability) {
            Write-Host "  Prometheus:     http://localhost:$(Get-EnvValue -Name 'PROMETHEUS_PORT' -Default '9090')"
            Write-Host "  Grafana:        http://localhost:$(Get-EnvValue -Name 'GRAFANA_PORT' -Default '3001')"
        }
    }
}
