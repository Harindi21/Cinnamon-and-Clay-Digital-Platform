$ErrorActionPreference = "Stop"

$adminRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $adminRoot

Set-Location $adminRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not available on PATH. Install Flutter stable first."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not available on PATH."
}

$trackedChanges = git -C $repoRoot status --porcelain --untracked-files=no
if ($trackedChanges) {
    throw "Commit or stash tracked changes before generating the Android platform."
}

Write-Host "Generating Android platform..."
flutter create `
    --platforms=android `
    --project-name cinnamon_clay_admin `
    --org dev.cinnamonandclay `
    .

if ($LASTEXITCODE -ne 0) {
    throw "flutter create failed."
}

Write-Host "Restoring repository-owned Flutter source after platform generation..."
git -C $repoRoot restore -- `
    admin-flutter/lib `
    admin-flutter/test `
    admin-flutter/pubspec.yaml `
    admin-flutter/pubspec.lock `
    admin-flutter/analysis_options.yaml `
    admin-flutter/README.md

$gradlePath = Join-Path $adminRoot "android\app\build.gradle.kts"
$mainManifestPath = Join-Path $adminRoot "android\app\src\main\AndroidManifest.xml"
$debugManifestPath = Join-Path $adminRoot "android\app\src\debug\AndroidManifest.xml"

if (-not (Test-Path $gradlePath)) {
    throw "Expected Android Gradle file was not generated: $gradlePath"
}

$gradle = Get-Content -Raw $gradlePath
$gradle = $gradle -replace "minSdk = flutter\.minSdkVersion", "minSdk = 23"

if ($gradle -notmatch "appAuthRedirectScheme") {
    $placeholder = @"
        manifestPlaceholders.putAll(
            mapOf(
                "appAuthRedirectScheme" to "dev.cinnamonandclay.admin"
            )
        )
"@

    $versionNamePattern = "(?m)^(\s*versionName = flutter\.versionName\s*)$"
    if ($gradle -notmatch $versionNamePattern) {
        throw "Could not find versionName in build.gradle.kts to add the AppAuth redirect scheme."
    }

    $gradle = [regex]::Replace(
        $gradle,
        $versionNamePattern,
        "`$1`r`n$placeholder"
    )
}

Set-Content -Path $gradlePath -Value $gradle -Encoding utf8

$mainManifest = Get-Content -Raw $mainManifestPath
if ($mainManifest -notmatch 'android:allowBackup=') {
    $mainApplicationEnd = @'
android:icon="@mipmap/ic_launcher"
        android:allowBackup="false">
'@
    $mainManifest = $mainManifest -replace `
        'android:icon="@mipmap/ic_launcher">', `
        $mainApplicationEnd.Trim()
}
Set-Content -Path $mainManifestPath -Value $mainManifest -Encoding utf8

$debugManifest = Get-Content -Raw $debugManifestPath
if ($debugManifest -notmatch 'usesCleartextTraffic') {
    $debugApplication = @'
    <application android:usesCleartextTraffic="true" />
</manifest>
'@
    $debugManifest = $debugManifest -replace `
        '</manifest>', `
        $debugApplication.TrimEnd()
}
Set-Content -Path $debugManifestPath -Value $debugManifest -Encoding utf8

Write-Host "Resolving Flutter dependencies..."
flutter pub get

if ($LASTEXITCODE -ne 0) {
    throw "flutter pub get failed."
}

Write-Host ""
Write-Host "Android OIDC bootstrap complete."
Write-Host ""
Write-Host "Before running an emulator/device:"
Write-Host "  adb reverse tcp:8080 tcp:8080"
Write-Host "  adb reverse tcp:8081 tcp:8081"
Write-Host ""
Write-Host "Then run:"
Write-Host "  flutter run --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay --dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile --dart-define=OIDC_ALLOW_INSECURE=true"
Write-Host ""
Write-Host "Review and commit the generated android/ folder and updated pubspec.lock."
