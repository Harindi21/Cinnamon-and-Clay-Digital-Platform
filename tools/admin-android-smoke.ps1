[CmdletBinding()]
param(
    [string]$DeviceId,
    [int]$BackendPort = 8082,
    [int]$KeycloakPort = 8081,
    [switch]$SkipUnitChecks,
    [switch]$SkipIntegrationTest,
    [switch]$SkipServicePreflight
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$adminRoot = Join-Path $root 'admin-flutter'
$androidRoot = Join-Path $adminRoot 'android'

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required but is not available on PATH."
    }
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(ValueFromRemainingArguments)][string[]]$Arguments
    )
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

function Wait-HttpEndpoint {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Name,
        [int]$Attempts = 20
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 3
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
                Write-Host "$Name ready: $Url"
                return
            }
            if ($attempt -eq $Attempts) {
                throw "$Name returned HTTP $($response.StatusCode) at $Url."
            }
        }
        catch {
            if ($attempt -eq $Attempts) {
                throw "$Name did not become ready at $Url. Last error: $($_.Exception.Message)"
            }
        }
        Start-Sleep -Seconds 1
    }
}

Assert-Command flutter
Assert-Command adb

if (-not (Test-Path -LiteralPath $androidRoot)) {
    throw 'admin-flutter/android is missing. Restore the committed Android runner from Git before continuing.'
}

if (-not $DeviceId) {
    $connected = @(
        & adb devices |
            Select-Object -Skip 1 |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '\sdevice$' } |
            ForEach-Object { ($_ -split '\s+')[0] }
    )
    if ($connected.Count -eq 0) {
        throw 'No Android emulator/device is connected. Start one and retry.'
    }
    if ($connected.Count -gt 1) {
        throw "Multiple Android devices are connected ($($connected -join ', ')). Pass -DeviceId explicitly."
    }
    $DeviceId = $connected[0]
}

Write-Host "Using Android device: $DeviceId"

if (-not $SkipServicePreflight) {
    Wait-HttpEndpoint -Name 'Backend readiness' -Url "http://localhost:$BackendPort/actuator/health/readiness"
    Wait-HttpEndpoint -Name 'Keycloak discovery' -Url "http://localhost:$KeycloakPort/realms/cinnamon-clay/.well-known/openid-configuration"
}

Invoke-Checked adb -s $DeviceId reverse "tcp:$BackendPort" "tcp:$BackendPort"
Invoke-Checked adb -s $DeviceId reverse "tcp:$KeycloakPort" "tcp:$KeycloakPort"

Push-Location $adminRoot
try {
    Invoke-Checked flutter pub get

    if (-not $SkipUnitChecks) {
        Invoke-Checked flutter analyze
        Invoke-Checked flutter test
    }

    $defines = @(
        '--dart-define=APP_ENVIRONMENT=local',
        "--dart-define=API_BASE_URL=http://localhost:$BackendPort",
        "--dart-define=OIDC_ISSUER_URL=http://localhost:$KeycloakPort/realms/cinnamon-clay",
        '--dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile',
        '--dart-define=OIDC_ALLOW_INSECURE=true'
    )

    Invoke-Checked flutter build apk --debug @defines
    $apk = Join-Path $adminRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk)) {
        throw "Expected debug APK was not produced: $apk"
    }

    Invoke-Checked adb -s $DeviceId install -r $apk

    $callback = & adb -s $DeviceId shell cmd package resolve-activity --brief `
        -a android.intent.action.VIEW `
        -c android.intent.category.BROWSABLE `
        -d 'dev.cinnamonandclay.admin:/oauthredirect'
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to resolve the AppAuth callback activity.'
    }
    $callbackText = ($callback | Out-String).Trim()
    if ($callbackText -notmatch 'net\.openid\.appauth\.RedirectUriReceiverActivity') {
        throw "OIDC callback did not resolve to AppAuth. Resolved value: $callbackText"
    }
    Write-Host "OIDC callback: $callbackText"

    if (-not $SkipIntegrationTest) {
        Invoke-Checked flutter test integration_test/app_smoke_test.dart -d $DeviceId @defines
    }

    Invoke-Checked adb -s $DeviceId shell am start -W `
        -n 'dev.cinnamonandclay.admin/.MainActivity'

    Write-Host ''
    Write-Host 'Android runner smoke passed.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Human OIDC verification:'
    Write-Host '  1. Ensure Keycloak and the backend are running locally.'
    Write-Host '  2. Open the installed Cinnamon & Clay Admin app.'
    Write-Host '  3. Tap Sign in and authenticate with a local Keycloak user.'
    Write-Host '  4. Confirm the browser returns to the app and the Catalog screen loads.'
    Write-Host '  5. Sign out and confirm the local session is cleared.'
}
finally {
    Pop-Location
}
