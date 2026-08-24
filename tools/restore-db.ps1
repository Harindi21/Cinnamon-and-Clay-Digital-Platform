param(
    [Parameter(Mandatory = $true)]
    [string]$BackupPath,
    [switch]$Force
)

. (Join-Path $PSScriptRoot '_env.ps1')
$root = Get-RepositoryRoot
Import-DotEnv -Path (Join-Path $root '.env')
Assert-CommandAvailable -Name 'docker'

if (-not $Force) {
    throw 'Restore is destructive. Re-run with -Force after stopping the backend and confirming the target database.'
}

$resolvedBackup = (Resolve-Path -LiteralPath $BackupPath).Path
Assert-BackupChecksum -BackupPath $resolvedBackup
$db = Get-EnvValue -Name 'POSTGRES_DB' -Default 'cinnamon_clay'
$user = Get-EnvValue -Name 'POSTGRES_USER' -Default 'cinnamon_clay'
$password = Get-EnvValue -Name 'POSTGRES_PASSWORD' -Default 'change-me-locally'
Assert-SafeSqlIdentifier -Value $db
Assert-SafeSqlIdentifier -Value $user

$container = 'cinnamon-clay-postgres'
$containerPath = '/tmp/cinnamon-clay-restore.dump'

try {
    & docker cp $resolvedBackup "${container}:$containerPath"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to copy backup into PostgreSQL container.' }

    $terminateSql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db' AND pid <> pg_backend_pid();"
    & docker exec -e "PGPASSWORD=$password" $container psql -U $user -d postgres -v ON_ERROR_STOP=1 -c $terminateSql
    if ($LASTEXITCODE -ne 0) { throw 'Unable to terminate target database connections.' }

    & docker exec -e "PGPASSWORD=$password" $container dropdb -U $user --if-exists $db
    if ($LASTEXITCODE -ne 0) { throw 'dropdb failed.' }
    & docker exec -e "PGPASSWORD=$password" $container createdb -U $user -O $user $db
    if ($LASTEXITCODE -ne 0) { throw 'createdb failed.' }
    & docker exec -e "PGPASSWORD=$password" $container pg_restore -U $user -d $db --no-owner --no-privileges --exit-on-error $containerPath
    if ($LASTEXITCODE -ne 0) { throw 'pg_restore failed.' }

    $verifySql = @"
SELECT
  to_regclass('public.menu_category') IS NOT NULL
  AND to_regclass('public.site_content') IS NOT NULL
  AND to_regclass('public.contact_profile') IS NOT NULL
  AND to_regclass('public.media_asset') IS NOT NULL
  AND to_regclass('public.review') IS NOT NULL
  AND to_regclass('public.admin_audit_event') IS NOT NULL;
"@
    $verified = & docker exec -e "PGPASSWORD=$password" $container `
        psql -U $user -d $db -v ON_ERROR_STOP=1 -At -c $verifySql
    if ($LASTEXITCODE -ne 0 -or ($verified | Select-Object -Last 1) -ne 't') {
        throw "Restore completed but schema verification failed: $verified"
    }

    Write-Host "Restore completed and core schema verified for database '$db'."
    Write-Host 'Run the backend and smoke tests before returning traffic.'
}
finally {
    & docker exec $container rm -f $containerPath 2>$null | Out-Null
}
