$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$adminRoot = Split-Path -Parent $PSScriptRoot
$settingsPath = Join-Path $adminRoot 'android\settings.gradle.kts'
$appBuildPath = Join-Path $adminRoot 'android\app\build.gradle.kts'

$expectedAgp = '9.1.1'
$expectedCompileSdk = 37
$expectedCompileSdkMinor = 0

if (-not (Test-Path -LiteralPath $settingsPath)) {
    throw "Android settings file not found: $settingsPath"
}
if (-not (Test-Path -LiteralPath $appBuildPath)) {
    throw "Android app build file not found: $appBuildPath"
}

$settings = Get-Content -LiteralPath $settingsPath -Raw
$appBuild = Get-Content -LiteralPath $appBuildPath -Raw

$agpPattern = 'id\("com\.android\.application"\)\s+version\s+"' + [regex]::Escape($expectedAgp) + '"\s+apply\s+false'
if ($settings -notmatch $agpPattern) {
    throw "Android Gradle Plugin must be pinned to $expectedAgp for the approved API 37 / Gradle 9.3.1 toolchain."
}

$compileSdkPattern = '(?s)compileSdk\s*\{\s*version\s*=\s*release\(\s*' + $expectedCompileSdk + '\s*\)\s*\{\s*minorApiLevel\s*=\s*' + $expectedCompileSdkMinor + '\s*\}\s*\}'
if ($appBuild -notmatch $compileSdkPattern) {
    throw "admin-flutter must compile against Android API $expectedCompileSdk.$expectedCompileSdkMinor using the minor-version-aware compileSdk DSL."
}

Write-Host "[PASS] Android toolchain contract: AGP $expectedAgp, compileSdk $expectedCompileSdk.$expectedCompileSdkMinor."
