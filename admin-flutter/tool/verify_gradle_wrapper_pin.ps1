$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$adminRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $adminRoot 'android\gradle\wrapper\gradle-wrapper.properties'

$expected = @{
    distributionUrl = 'https\://services.gradle.org/distributions/gradle-9.3.1-bin.zip'
    distributionSha256Sum = 'b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06'
}

if (-not (Test-Path -LiteralPath $propertiesPath)) {
    throw "Gradle wrapper properties not found: $propertiesPath"
}

$actual = @{}
Get-Content -LiteralPath $propertiesPath | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith('#')) {
        return
    }

    $separator = $line.IndexOf('=')
    if ($separator -le 0) {
        return
    }

    $key = $line.Substring(0, $separator).Trim()
    $value = $line.Substring($separator + 1).Trim()
    $actual[$key] = $value
}

foreach ($key in $expected.Keys) {
    if (-not $actual.ContainsKey($key)) {
        throw "Missing required Gradle wrapper property '$key'."
    }
    if ($actual[$key] -ne $expected[$key]) {
        throw @"
Gradle wrapper integrity pin mismatch for '$key'.
Expected: $($expected[$key])
Actual:   $($actual[$key])
Review the Gradle release checksum before changing this pin.
"@
    }
}

Write-Host '[PASS] Gradle 9.3.1 distribution URL and SHA-256 pin are approved.'
