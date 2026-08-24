param(
    [string]$OutputDirectory
)

. (Join-Path $PSScriptRoot '_env.ps1')
$root = Get-RepositoryRoot
Import-DotEnv -Path (Join-Path $root '.env')
Assert-CommandAvailable -Name 'docker'

$db = Get-EnvValue -Name 'POSTGRES_DB' -Default 'cinnamon_clay'
$user = Get-EnvValue -Name 'POSTGRES_USER' -Default 'cinnamon_clay'
$password = Get-EnvValue -Name 'POSTGRES_PASSWORD' -Default 'change-me-locally'
Assert-SafeSqlIdentifier -Value $db
Assert-SafeSqlIdentifier -Value $user

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'backups'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$fileName = "$db-$timestamp.dump"
$containerPath = "/tmp/$fileName"
$hostPath = Join-Path (Resolve-Path $OutputDirectory).Path $fileName
$container = 'cinnamon-clay-postgres'

try {
    & docker exec -e "PGPASSWORD=$password" $container `
        pg_dump -U $user -d $db -Fc --no-owner --no-privileges -f $containerPath
    if ($LASTEXITCODE -ne 0) { throw 'pg_dump failed.' }

    & docker cp "${container}:$containerPath" $hostPath
    if ($LASTEXITCODE -ne 0) { throw 'docker cp failed.' }

    $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $hostPath).Hash.ToLowerInvariant()
    $metadata = [ordered]@{
        database = $db
        createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        sha256 = $sha256
        file = $fileName
        format = 'pg_dump-custom'
    }
    $metadataPath = "$hostPath.json"
    $metadata | ConvertTo-Json | Set-Content -LiteralPath $metadataPath -Encoding UTF8

    Write-Host "Backup created: $hostPath"
    Write-Host "SHA-256: $sha256"
    Write-Host "Metadata: $metadataPath"
}
finally {
    & docker exec $container rm -f $containerPath 2>$null | Out-Null
}
