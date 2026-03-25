SV-TMS server deployment helper

Overview
- This `infra/` folder contains helper files to deploy the sv-tms repo to an Ubuntu 24 VPS.
- Files:
  - `deploy.sh` — local helper that rsyncs the repo to the server and runs basic server setup.
  - `docker-compose.prod.yml` — production split-service stack with persistent storage.
  - `nginx/site.conf` — nginx reverse proxy for `admin-web-ui` and `api-gateway`.
  - `scripts/backup_stack.sh` — full-stack backup for DBs, uploads, spool, message store, and Redis persistence.
  - `scripts/restore_stack.sh` — full-stack restore.
  - `scripts/verify_backup.sh` — checksum verification for backups.
  - `scripts/sync_backups_offsite.sh` — replicate backups to a secondary host or cloud remote.
  - `DATA_DURABILITY.md` — backup and restore runbook.
  - `MONITORING.md` — Prometheus, Grafana, exporters, and alerting guide.

Before you run
1. Do NOT share passwords in plain text. Copy `infra/.env.example` to `infra/.env` and replace every placeholder secret before deploy.
2. Set up SSH key auth from your local machine to the VPS. Test with `ssh root@your_vps`.
3. Ensure DNS for your domain points to your VPS public IP.

Quick deploy (example)

Replace placeholders then run locally from repo root:

```bash
# Example (replace values):
SERVER=root@207.180.245.156
DOMAIN=svtms.svtrucking.biz
EMAIL=you@yourdomain.tld

# Copy env example to infra/.env and edit secrets
cp infra/.env.example infra/.env
# Edit infra/.env and set secure passwords and EMAIL
nano infra/.env

# Sync repo and run initial setup
./infra/deploy.sh --repo . --server "$SERVER" --domain "$DOMAIN" --email "$EMAIL"
```

After deploy on server
1. Ensure `infra/.env` is present in `/opt/sv-tms/infra/.env` on the server (the deploy script syncs files). Verify values.
2. Restart the production stack:

```bash
ssh root@207.180.245.156
cd /opt/sv-tms
docker compose pull || true
docker compose --env-file infra/.env -f infra/docker-compose.prod.yml up -d --remove-orphans
```

3. Obtain TLS certificates for `svtms.svtrucking.biz` using certbot (on the server):

```bash
# Install certbot if not present
snap install --classic certbot || true
ln -s /snap/bin/certbot /usr/bin/certbot || true

# Use the nginx plugin to obtain and install certificates
certbot --nginx -d svtms.svtrucking.biz -m you@yourdomain.tld --agree-tos --no-eff-email

# Or use webroot when nginx serves /.well-known from /var/www/certbot
certbot certonly --webroot -w /var/www/certbot -d svtms.svtrucking.biz -m you@yourdomain.tld --agree-tos --no-eff-email
```

Notes: create `/opt/sv-tms/infra/.env` from the example and keep secrets out of source control. Consider using a vault or environment-specific secrets management for production.

Notes & next steps
- If you prefer fully automated cert provisioning, consider adding a small certbot container or using the `nginx-certbot` Docker pattern.
- Use [DATA_DURABILITY.md](/Users/sotheakh/Documents/develop/sv-tms/infra/DATA_DURABILITY.md) as the operations checklist.
- Schedule `infra/scripts/backup_stack.sh` and `infra/scripts/verify_backup.sh`.
- Configure `BACKUP_OFFSITE_TARGET` or `RCLONE_REMOTE` and enable the off-site sync timer for host-loss protection.
- If your Java services use MapStruct/Lombok, keep CI green before deploy so the server is not the first place builds are validated.

Need help?
- Run the deploy and paste any errors; I'll help debug logs and fix the scripts.
