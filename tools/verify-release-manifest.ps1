param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [switch]$VerifySignatures
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$digestPattern = '^sha256:[0-9a-f]{64}$'

if ($manifest.schemaVersion -ne '1') {
    throw "Unsupported schemaVersion '$($manifest.schemaVersion)'."
}
if ([string]::IsNullOrWhiteSpace($manifest.releaseVersion)) {
    throw 'releaseVersion is required.'
}

$images = @(
    @{ Name = 'backend'; Value = $manifest.images.backend },
    @{ Name = 'publicWeb'; Value = $manifest.images.publicWeb }
)

foreach ($entry in $images) {
    $image = $entry.Value
    if ($null -eq $image) {
        throw "Missing $($entry.Name) image."
    }
    if ($image.ref -notmatch '^ghcr\.io/') {
        throw "$($entry.Name) ref must point to ghcr.io."
    }
    if ($image.digest -notmatch $digestPattern) {
        throw "$($entry.Name) digest is not an immutable sha256 digest."
    }

    Write-Host "[PASS] $($entry.Name): $($image.ref)@$($image.digest)"

    if ($VerifySignatures) {
        if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
            throw 'cosign is required when -VerifySignatures is supplied.'
        }

        & cosign verify `
            '--certificate-identity-regexp' '^https://github.com/.+/.github/workflows/release.yml@refs/(tags|heads)/' `
            '--certificate-oidc-issuer' 'https://token.actions.githubusercontent.com' `
            "$($image.ref)@$($image.digest)"
        if ($LASTEXITCODE -ne 0) {
            throw "Signature verification failed for $($entry.Name)."
        }
    }
}

Write-Host "Release manifest '$ManifestPath' is structurally valid."
