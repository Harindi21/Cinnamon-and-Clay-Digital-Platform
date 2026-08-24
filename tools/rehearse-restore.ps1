param(
    [Parameter(Mandatory = $true)]
    [string]$BackupPath
)

. (Join-Path $PSScriptRoot '_env.ps1')
$root = Get-RepositoryRoot
Import-DotEnv -Path (Join-Path $root '.env')
Assert-CommandAvailable -Name 'docker'

$resolvedBackup = (Resolve-Path -LiteralPath $BackupPath).Path
Assert-BackupChecksum -BackupPath $resolvedBackup
$user = Get-EnvValue -Name 'POSTGRES_USER' -Default 'cinnamon_clay'
$password = Get-EnvValue -Name 'POSTGRES_PASSWORD' -Default 'change-me-locally'
Assert-SafeSqlIdentifier -Value $user

$container = 'cinnamon-clay-postgres'
$suffix = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$rehearsalDb = "cinnamon_clay_restore_${suffix}_$PID"
Assert-SafeSqlIdentifier -Value $rehearsalDb
$containerPath = '/tmp/cinnamon-clay-rehearsal.dump'
$started = Get-Date

try {
    & docker cp $resolvedBackup "${container}:$containerPath"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to copy backup into PostgreSQL container.' }

    & docker exec -e "PGPASSWORD=$password" $container createdb -U $user -O $user $rehearsalDb
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create rehearsal database.' }

    & docker exec -e "PGPASSWORD=$password" $container pg_restore -U $user -d $rehearsalDb --no-owner --no-privileges --exit-on-error $containerPath
    if ($LASTEXITCODE -ne 0) { throw 'Rehearsal pg_restore failed.' }

    $verifySql = @"
SELECT
  (SELECT version FROM flyway_schema_history WHERE success = true ORDER BY installed_rank DESC LIMIT 1) AS flyway_version,
  to_regclass('public.menu_category') IS NOT NULL AS has_catalog,
  to_regclass('public.site_content') IS NOT NULL AS has_content,
  to_regclass('public.contact_profile') IS NOT NULL AS has_contact,
  to_regclass('public.media_asset') IS NOT NULL AS has_media,
  to_regclass('public.review') IS NOT NULL AS has_reviews,
  to_regclass('public.admin_audit_event') IS NOT NULL AS has_audit;
"@
    $verification = & docker exec -e "PGPASSWORD=$password" $container `
        psql -U $user -d $rehearsalDb -v ON_ERROR_STOP=1 -At -F '|' -c $verifySql
    if ($LASTEXITCODE -ne 0) { throw 'Restore verification query failed.' }

    $parts = ($verification | Select-Object -Last 1).Split('|')
    if ($parts.Count -ne 7 -or ($parts[1..6] -contains 'f')) {
        throw "Restore verification failed: $verification"
    }

    $duration = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
    Write-Host 'RESTORE REHEARSAL PASSED'
    Write-Host "  Flyway version: $($parts[0])"
    Write-Host "  Duration: ${duration}s"
    Write-Host "  Temporary database: $rehearsalDb"
}
finally {
    & docker exec -e "PGPASSWORD=$password" $container dropdb -U $user --if-exists --force $rehearsalDb 2>$null | Out-Null
    & docker exec $container rm -f $containerPath 2>$null | Out-Null
}
