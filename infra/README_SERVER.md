Server-side helper scripts (infra/scripts)

Place these scripts in `/opt/sv-tms/infra/scripts` on the server and make them executable:

- `backup_stack.sh` — create a full-stack backup set covering MySQL, Postgres, Mongo, uploads, Redis persisted files, telematics spool, and message-audit storage.
- `restore_stack.sh` — restore a backup set into the production split stack.
- `verify_backup.sh` — verify checksums for the latest or specified backup set.
- `sync_backups_offsite.sh` — replicate backups to a second host or cloud remote.
- `preflight_prod.sh` — validate env, persistence paths, and compose rendering before rollout.
- `restore_drill.sh` — prepare a disposable restore-drill workspace from the latest backup set.
- `post_deploy_smoke.sh` — verify the split services and edge route are healthy after deploy or restore.
- `deploy_stack.sh` — pull/build/start the production split stack and attempt certbot webroot issuance if `infra/.env` contains `DOMAIN` and `EMAIL`.
- Monitoring is documented in [MONITORING.md](/Users/sotheakh/Documents/develop/sv-tms/infra/MONITORING.md).

Install & usage (on server)
```bash
# copy scripts to server or they will be synced by the deploy process
mkdir -p /opt/sv-tms/infra/scripts
# copy from repo root (local):
rsync -avz infra/scripts/ root@207.180.245.156:/opt/sv-tms/infra/scripts/

# on server
chmod +x /opt/sv-tms/infra/scripts/*.sh

# run backup
/opt/sv-tms/infra/scripts/backup_stack.sh

# verify latest backup
/opt/sv-tms/infra/scripts/verify_backup.sh

# sync off-host if BACKUP_OFFSITE_TARGET or RCLONE_REMOTE is configured
/opt/sv-tms/infra/scripts/sync_backups_offsite.sh

# preflight before deploy
/opt/sv-tms/infra/scripts/preflight_prod.sh

# post-deploy smoke validation
/opt/sv-tms/infra/scripts/post_deploy_smoke.sh

# restore from latest
/opt/sv-tms/infra/scripts/restore_stack.sh

# prepare a restore rehearsal workspace
/opt/sv-tms/infra/scripts/restore_drill.sh

# deploy stack (pull/build/up and request certs)
/opt/sv-tms/infra/scripts/deploy_stack.sh
```

Notes
- All scripts read DB credentials and DOMAIN/EMAIL from `/opt/sv-tms/infra/.env` when present.
- Ensure `/opt/sv-tms/infra/.env` is present and `chmod 600` to protect secrets.
- Check `docker compose --env-file /opt/sv-tms/infra/.env -f /opt/sv-tms/infra/docker-compose.prod.yml ps` and logs for troubleshooting.

Security
- Do NOT commit `/opt/sv-tms/infra/.env` to git. Keep it local to the server and restrict permissions.
- Regularly rotate DB passwords and store them safely.

Automation
- Install the units in [infra/systemd](/Users/sotheakh/Documents/develop/sv-tms/infra/systemd) for scheduled backups and certificate renewal.
- Install the off-site sync timer too if you configure `BACKUP_OFFSITE_TARGET` or `RCLONE_REMOTE`.
- If you prefer cron, schedule `backup_stack.sh` and `verify_backup.sh` together, and run a regular restore drill in staging.
