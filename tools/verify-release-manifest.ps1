param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [string]$ExpectedReleaseVersion,

    [string]$ExpectedRepository,

    [string]$ExpectedSourceRevision,

    [string]$ReleaseTag,

    [switch]$VerifySignatures
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$digestPattern = '^sha256:[0-9a-f]{64}$'
$revisionPattern = '^[0-9a-f]{40}$'
$semVerPattern = '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
$repositoryPattern = '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'

if ($manifest.schemaVersion -ne '1') {
    throw "Unsupported schemaVersion '$($manifest.schemaVersion)'."
}
if ([string]::IsNullOrWhiteSpace($manifest.releaseVersion) -or $manifest.releaseVersion -notmatch $semVerPattern) {
    throw 'releaseVersion must be a valid SemVer value.'
}
if ($ExpectedReleaseVersion -and $manifest.releaseVersion -ne $ExpectedReleaseVersion) {
    throw "releaseVersion '$($manifest.releaseVersion)' does not match expected '$ExpectedReleaseVersion'."
}
if ($null -eq $manifest.source) {
    throw 'source is required.'
}
if ([string]::IsNullOrWhiteSpace($manifest.source.repository) -or $manifest.source.repository -notmatch $repositoryPattern) {
    throw 'source.repository must be an owner/repository value.'
}
if ($ExpectedRepository -and $manifest.source.repository -ne $ExpectedRepository) {
    throw "source.repository '$($manifest.source.repository)' does not match expected '$ExpectedRepository'."
}
if ([string]::IsNullOrWhiteSpace($manifest.source.revision) -or $manifest.source.revision -notmatch $revisionPattern) {
    throw 'source.revision must be a 40-character lowercase Git SHA.'
}
if ($ExpectedSourceRevision -and $manifest.source.revision -ne $ExpectedSourceRevision) {
    throw "source.revision '$($manifest.source.revision)' does not match expected '$ExpectedSourceRevision'."
}

$owner = ($manifest.source.repository -split '/', 2)[0].ToLowerInvariant()
$images = @(
    @{
        Name = 'backend'
        Value = $manifest.images.backend
        ExpectedRef = "ghcr.io/$owner/cinnamon-clay-backend"
        ExpectedSbom = 'backend.cdx.json'
    },
    @{
        Name = 'publicWeb'
        Value = $manifest.images.publicWeb
        ExpectedRef = "ghcr.io/$owner/cinnamon-clay-public-web"
        ExpectedSbom = 'public-web.cdx.json'
    }
)

foreach ($entry in $images) {
    $image = $entry.Value
    if ($null -eq $image) {
        throw "Missing $($entry.Name) image."
    }
    if ($image.ref -ne $entry.ExpectedRef) {
        throw "$($entry.Name) ref must be '$($entry.ExpectedRef)'."
    }
    if ($image.digest -notmatch $digestPattern) {
        throw "$($entry.Name) digest is not an immutable sha256 digest."
    }
    if ($image.sbom -ne $entry.ExpectedSbom) {
        throw "$($entry.Name) SBOM must be '$($entry.ExpectedSbom)'."
    }

    Write-Host "[PASS] $($entry.Name): $($image.ref)@$($image.digest)"

    if ($VerifySignatures) {
        if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
            throw 'cosign is required when -VerifySignatures is supplied.'
        }

        $issuer = 'https://token.actions.githubusercontent.com'
        if ($ReleaseTag) {
            if ($ReleaseTag -notmatch ('^v' + $semVerPattern.Substring(1))) {
                throw "ReleaseTag '$ReleaseTag' must be v<SemVer>."
            }
            $identity = "https://github.com/$($manifest.source.repository)/.github/workflows/release.yml@refs/tags/$ReleaseTag"
            & cosign verify `
                '--certificate-identity' $identity `
                '--certificate-oidc-issuer' $issuer `
                "$($image.ref)@$($image.digest)"
        }
        else {
            $repository = [regex]::Escape([string]$manifest.source.repository)
            $identityPattern = "^https://github.com/$repository/.github/workflows/release\.yml@refs/(tags|heads)/"
            & cosign verify `
                '--certificate-identity-regexp' $identityPattern `
                '--certificate-oidc-issuer' $issuer `
                "$($image.ref)@$($image.digest)"
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Signature verification failed for $($entry.Name)."
        }
    }
}

Write-Host "Release manifest '$ManifestPath' is structurally valid."
