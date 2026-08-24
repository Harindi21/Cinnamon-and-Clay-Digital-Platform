param(
    [switch]$IncludeWeb,
    [switch]$Observability
)

. (Join-Path $PSScriptRoot '_env.ps1')
$root = Get-RepositoryRoot
Import-DotEnv -Path (Join-Path $root '.env')

$backendPort = Get-EnvValue -Name 'BACKEND_PORT' -Default '8082'
$webPort = Get-EnvValue -Name 'PUBLIC_WEB_PORT' -Default '3000'
$keycloakPort = Get-EnvValue -Name 'KEYCLOAK_PORT' -Default '8081'
$minioPort = Get-EnvValue -Name 'MINIO_API_PORT' -Default '9000'

function Assert-HttpReady {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Uri
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
            throw "HTTP $($response.StatusCode)"
        }
        Write-Host "[PASS] $Name -> $Uri"
    }
    catch {
        throw "[FAIL] $Name -> $Uri :: $($_.Exception.Message)"
    }
}

Assert-HttpReady -Name 'Backend health' -Uri "http://127.0.0.1:$backendPort/actuator/health"
Assert-HttpReady -Name 'Public catalog' -Uri "http://127.0.0.1:$backendPort/api/v1/catalog/menu"
Assert-HttpReady -Name 'Public content' -Uri "http://127.0.0.1:$backendPort/api/v1/content/site"
Assert-HttpReady -Name 'Public contact' -Uri "http://127.0.0.1:$backendPort/api/v1/contact"
Assert-HttpReady -Name 'Public media' -Uri "http://127.0.0.1:$backendPort/api/v1/media"
Assert-HttpReady -Name 'Public reviews' -Uri "http://127.0.0.1:$backendPort/api/v1/reviews"
Assert-HttpReady -Name 'Keycloak discovery' -Uri "http://127.0.0.1:$keycloakPort/realms/cinnamon-clay/.well-known/openid-configuration"
Assert-HttpReady -Name 'MinIO health' -Uri "http://127.0.0.1:$minioPort/minio/health/live"

if ($IncludeWeb) {
    Assert-HttpReady -Name 'Public web' -Uri "http://127.0.0.1:$webPort"
}

if ($Observability) {
    $prometheusPort = Get-EnvValue -Name 'PROMETHEUS_PORT' -Default '9090'
    $grafanaPort = Get-EnvValue -Name 'GRAFANA_PORT' -Default '3001'
    Assert-HttpReady -Name 'Prometheus readiness' -Uri "http://127.0.0.1:$prometheusPort/-/ready"
    Assert-HttpReady -Name 'Grafana health' -Uri "http://127.0.0.1:$grafanaPort/api/health"
}

Write-Host 'LOCAL SMOKE CHECK PASSED'
