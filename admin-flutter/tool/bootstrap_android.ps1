$ErrorActionPreference = 'Stop'

$adminRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $adminRoot
$androidRoot = Join-Path $adminRoot 'android'

if (-not (Test-Path -LiteralPath $androidRoot)) {
    throw @'
The Android runner is repository-owned now and should not be regenerated in place.
Restore admin-flutter/android from Git, or generate a temporary Flutter 3.47.1 project
only when intentionally reviewing upstream template changes.
'@
}

Write-Warning 'bootstrap_android.ps1 is retained for compatibility; the Android runner is already committed.'
Write-Host 'Running the repository Android smoke verifier instead...'

& (Join-Path $repoRoot 'tools\admin-android-smoke.ps1') @args
if (-not $?) { exit 1 }
