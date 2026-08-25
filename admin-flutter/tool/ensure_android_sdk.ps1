[CmdletBinding()]
param(
    [ValidateRange(1, 99)]
    [int]$CompileSdk = 37,
    [ValidateRange(0, 99)]
    [int]$CompileSdkMinor = 0,
    [string]$BuildToolsVersion = '36.0.0'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$sdkRoot = if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
    $env:ANDROID_SDK_ROOT
}
elseif (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
    $env:ANDROID_HOME
}
else {
    throw 'ANDROID_SDK_ROOT or ANDROID_HOME must point to an installed Android SDK.'
}

$isWindowsPlatform = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
$sdkManagerName = if ($isWindowsPlatform) { 'sdkmanager.bat' } else { 'sdkmanager' }
$candidates = @(
    (Join-Path $sdkRoot "cmdline-tools/latest/bin/$sdkManagerName"),
    (Join-Path $sdkRoot "tools/bin/$sdkManagerName")
)

$sdkManager = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $sdkManager) {
    $command = Get-Command sdkmanager -ErrorAction SilentlyContinue
    if ($command) {
        $sdkManager = $command.Source
    }
}

if (-not $sdkManager) {
    throw "sdkmanager was not found under '$sdkRoot' or on PATH. Install Android command-line tools first."
}

# Android API 37 uses the minor-versioned SDK package identifier android-37.0.
# The Gradle DSL mirrors that identity with release(37) + minorApiLevel = 0.
$platformVersion = "$CompileSdk.$CompileSdkMinor"
$platformPackage = "platforms;android-$platformVersion"
$packages = @(
    $platformPackage,
    "build-tools;$BuildToolsVersion"
)

Write-Host "Ensuring Android SDK packages are installed: $($packages -join ', ')"
& $sdkManager "--sdk_root=$sdkRoot" @packages
$installExitCode = $LASTEXITCODE
if ($installExitCode -ne 0) {
    Write-Host "sdkmanager could not install '$platformPackage'. Matching remote platform entries:"
    & $sdkManager "--sdk_root=$sdkRoot" --list 2>&1 |
        Select-String -Pattern "platforms;android-($CompileSdk|CinnamonBun)" |
        ForEach-Object { Write-Host $_.Line }
    throw "sdkmanager failed with exit code $installExitCode."
}

$platformPath = Join-Path $sdkRoot "platforms/android-$platformVersion"
$buildToolsPath = Join-Path $sdkRoot "build-tools/$BuildToolsVersion"
if (-not (Test-Path -LiteralPath $platformPath)) {
    throw "Android API $platformVersion was not installed at '$platformPath'."
}
if (-not (Test-Path -LiteralPath $buildToolsPath)) {
    throw "Android Build Tools $BuildToolsVersion were not installed at '$buildToolsPath'."
}

Write-Host "[PASS] Android API $platformVersion and Build Tools $BuildToolsVersion are available."
