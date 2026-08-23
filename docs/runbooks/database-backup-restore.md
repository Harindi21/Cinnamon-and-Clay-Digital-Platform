# Database backup and restore runbook

The repository includes executable local backup, restore and restore-rehearsal tooling. A production provider should still supply encrypted/off-site retention and, where available, point-in-time recovery.

## Create a backup

With PostgreSQL running:

```powershell
powershell -ExecutionPolicy Bypass -File tools/backup-db.ps1
```

The command writes a PostgreSQL custom-format dump to the ignored `backups/` directory together with JSON metadata containing the creation time and SHA-256 checksum. Restore and rehearsal commands verify that checksum when the metadata sidecar is present before touching a database.

Backups must never be committed to Git.

## Rehearse a restore safely

Do this regularly and before relying on a backup for a destructive migration:

```powershell
powershell -ExecutionPolicy Bypass -File tools/rehearse-restore.ps1 `
  -BackupPath backups/cinnamon_clay-<timestamp>.dump
```

The rehearsal:

1. verifies the backup checksum when sidecar metadata exists;
2. creates a temporary database;
3. restores the selected dump;
4. verifies Flyway history and the catalog/content/contact/media/review/audit tables;
5. reports elapsed restore time;
6. drops the temporary database in a `finally` cleanup path.

A backup that has not passed a restore rehearsal is not considered trusted.

## Restore the development database

Stop the backend first. Then run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/restore-db.ps1 `
  -BackupPath backups/cinnamon_clay-<timestamp>.dump `
  -Force
```

This is destructive: it terminates current connections, recreates the configured development database, and restores the dump.

Afterward:

1. start the backend;
2. verify `/actuator/health`;
3. verify public catalog/content endpoints;
4. verify an administrator login and read-only audit query;
5. record the restore result and elapsed time if this is a formal rehearsal.

## Media recovery boundary

The PostgreSQL dump contains media **metadata**, not S3/MinIO image bytes. A full production recovery plan must pair database recovery with versioning/backup/replication for the configured object-storage bucket and verify that referenced object keys are available after restore. The administrator orphan report is a reconciliation aid, not an object-storage backup.

## Production expectations

Before production launch, define and evidence:

- encrypted automated backups;
- off-site/provider-managed retention;
- restore access separated from normal application credentials;
- a scheduled restore rehearsal;
- measured recovery time objective (RTO);
- measured recovery point objective (RPO);
- point-in-time recovery where supported;
- object-storage versioning/backup/replication and a database-to-object reconciliation check;
- a pre-migration backup/rollback decision for destructive changes.

The local scripts prove the restore procedure and provide repeatable rehearsal mechanics; they are not a substitute for provider-level backup scheduling and retention.
