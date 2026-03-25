SV-TMS Data Durability Runbook

Scope
- MySQL: core transactional data
- Postgres: telematics/session/live tracking data
- MongoDB: location history secondary store
- Redis: append-only operational cache persistence
- Kafka: message/event log retention on disk
- Uploads: proofs, documents, generated assets
- Telematics spool: outage buffer for history replay
- Message API local store: delivery audit persistence

Production requirements
- Run the split platform from [docker-compose.prod.yml](/Users/sotheakh/Documents/develop/sv-tms/infra/docker-compose.prod.yml).
- Keep `DATA_ROOT` on persistent storage.
- Do not store production state inside container writable layers.
- Keep `infra/.env` out of git and rotate secrets periodically.

Backups
- Run [backup_stack.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/backup_stack.sh) on a schedule.
- Run [verify_backup.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/verify_backup.sh) after each backup.
- Run [sync_backups_offsite.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/sync_backups_offsite.sh) to copy backup sets off-host.
- Run [restore_drill.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/restore_drill.sh) before scheduled restore rehearsals.
- Retain backups off-host if you want protection from server loss, not just container loss.

Recommended schedule
- Full stack backup every 6 hours minimum.
- Nightly off-host copy to object storage or a second server.
- Monthly restore drill into staging.

What the backup includes
- `mysqldump` of core MySQL
- `pg_dump -Fc` of telematics Postgres
- `mongodump --archive --gzip` of Mongo
- Tar archives of uploads, telematics spool, message-api data, and Redis persisted files
- SHA-256 manifest for integrity verification

Operational limits
- This compose layout is durable for a single host, not multi-node HA.
- Kafka replication factor is still `1` in this topology.
- Redis persistence reduces loss risk but Redis is still not a system-of-record for business events.

Restore order
1. Stop write-capable services.
2. Restore MySQL and Postgres.
3. Restore MongoDB.
4. Restore uploads, telematics spool, message-api data, and Redis data.
5. Start services.
6. Verify health endpoints, queue replay, and upload availability.
