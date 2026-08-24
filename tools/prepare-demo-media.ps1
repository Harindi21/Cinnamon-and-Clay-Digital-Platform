param(
    [string]$Destination,
    [switch]$Upload,
    [string]$AccessToken = $env:ADMIN_ACCESS_TOKEN,
    [string]$BackendBaseUrl = 'http://127.0.0.1:8082'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_env.ps1')

Assert-CommandAvailable -Name 'curl.exe'

$root = Get-RepositoryRoot
$manifestPath = Join-Path $root 'demos/cinnamon-clay-media.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Join-Path $root '.local/demo-media'
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

if ($Upload -and [string]::IsNullOrWhiteSpace($AccessToken)) {
    throw 'Upload requested but no administrator access token was supplied. Pass -AccessToken or set ADMIN_ACCESS_TOKEN.'
}

$existingAssets = @()
if ($Upload) {
    $existingJson = & curl.exe `
        '--fail-with-body' `
        '--silent' `
        '--show-error' `
        '--header' "Authorization: Bearer $AccessToken" `
        "$($BackendBaseUrl.TrimEnd('/'))/api/v1/admin/media"
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to read existing administrator media before demo upload.'
    }
    $existingResponse = $existingJson | ConvertFrom-Json
    $existingAssets = @($existingResponse.assets)
}

Write-Host $manifest.sourceNote
Write-Host "Preparing demo media in $Destination"

foreach ($asset in $manifest.assets) {
    $filePath = Join-Path $Destination ([string]$asset.fileName)

    if (-not (Test-Path -LiteralPath $filePath)) {
        Write-Host "Downloading $($asset.fileName)..."
        & curl.exe `
            '--location' `
            '--fail' `
            '--silent' `
            '--show-error' `
            '--output' $filePath `
            ([string]$asset.url)
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to download $($asset.fileName)."
        }
    }
    else {
        Write-Host "Already present: $($asset.fileName)"
    }

    if ($Upload) {
        $existing = $existingAssets | Where-Object {
            $_.originalFilename -eq $asset.fileName -and
            $_.purpose -eq $asset.purpose
        } | Select-Object -First 1
        if ($null -ne $existing) {
            Write-Host "Already uploaded: $($asset.fileName) as $($asset.purpose)"
            continue
        }

        Write-Host "Uploading $($asset.fileName) as $($asset.purpose)..."
        $response = & curl.exe `
            '--request' 'POST' `
            '--fail-with-body' `
            '--silent' `
            '--show-error' `
            '--header' "Authorization: Bearer $AccessToken" `
            '--form' "file=@$filePath" `
            '--form' "purpose=$($asset.purpose)" `
            '--form' "altText=$($asset.altText)" `
            '--form' "caption=$($asset.caption)" `
            '--form' "focalXPercent=$($asset.focalXPercent)" `
            '--form' "focalYPercent=$($asset.focalYPercent)" `
            '--form' "sortOrder=$($asset.sortOrder)" `
            '--form' "active=$($asset.active.ToString().ToLowerInvariant())" `
            "$($BackendBaseUrl.TrimEnd('/'))/api/v1/admin/media"
        if ($LASTEXITCODE -ne 0) {
            throw "Upload failed for $($asset.fileName). Response: $response"
        }
    }
}

Write-Host ''
if ($Upload) {
    Write-Host 'Demo media upload complete. Refresh the Flutter Media workspace and public website.'
}
else {
    Write-Host 'Demo images are ready for local use.'
    Write-Host 'Open Flutter > Media > Gallery > Upload batch to select the gallery files.'
    Write-Host 'Upload hero-cafe.jpg and about-cafe.jpg using their respective placement controls.'
    Write-Host 'For scripted upload, rerun with -Upload -AccessToken <token>.'
}
