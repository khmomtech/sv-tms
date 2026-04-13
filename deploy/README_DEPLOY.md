Quick deploy & DB backup helpers

Canonical docs first:
- `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/INFRASTRUCTURE_GUIDE.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/DEVELOPMENT_GUIDE.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/ONGOING_MAINTENANCE_GUIDE.md`

Operational runbook:
- `docs/deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md` documents the current VPS layout, health checks, log checks, rollback, DB reset flow, and frontend cache/login-socket fix.
- `deploy/DISPATCH_WORKFLOW_ROLLOUT_CHECKLIST.md` is the staging/pilot/production checklist for GENERAL/KHBL/POL/POD rollout validation.

Morning release orchestrator (split microservices):
- `deploy/prod_morning_release_split_vps.sh` runs preflight build/tests, backup verification, service health, routing/OpenAPI/dynamic-policy smoke gates, optional dispatch-workflow smoke, rollback readiness, and writes a handover template.
- `deploy/post_release_stabilization_watch_vps.sh` captures 60-minute post-release snapshots (service status, health, auth/driver logs, nginx errors) into `deploy/reports/`.

Files added (deploy/):
- `backup_and_transfer_db.sh` — create local mysqldump (gzipped) and scp to VPS.
- `deploy_backend.sh` — build (if needed), scp jar to VPS and install systemd service using `tms-backend.service.template`.
- `tms-backend.service.template` — systemd unit template; copies to `/etc/systemd/system/<service>.service` on deploy.
- `nginx_tms_backend.conf.template` — nginx site example for reverse proxying to backend.
- `tms-telematics.service.template` — systemd unit template for the telematics microservice.
- `tms-telematics.env.postgresql.example` — example `/etc/default/tms-telematics` environment file for PostgreSQL-backed telematics.
- `nginx_tms_microservices.conf.template` — single-host path routing for backend + telematics.

Basic usage examples

0) Post-deploy smoke check (backend + frontends)

```bash
chmod +x deploy/post_deploy_smoke_check_vps.sh

# password auth (requires sshpass, do not commit SSHPASS anywhere)
SSHPASS='YOUR_VPS_PASSWORD' ./deploy/post_deploy_smoke_check_vps.sh \
  --vps root@207.180.245.156 --password-auth

# or SSH key auth
./deploy/post_deploy_smoke_check_vps.sh --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519
```

0.1) Post-deploy microservice routing smoke check (auth + driver-app)

```bash
chmod +x deploy/post_deploy_microservices_routing_smoke_vps.sh

# password auth
SSHPASS='YOUR_VPS_PASSWORD' ./deploy/post_deploy_microservices_routing_smoke_vps.sh \
  --vps root@207.180.245.156 --password-auth \
  --public-url https://svtms.svtrucking.biz

# SSH key auth
./deploy/post_deploy_microservices_routing_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz
```

This validates:
- `tms-auth-api` and `tms-driver-app-api` local health (`/actuator/health`)
- nginx split routing for:
  - `/api/auth/**` and `/api/driver/device/**` (auth-owned)
  - `/api/driver/**`, `/api/driver-app/**`, `/ws-sockjs/**` (driver-app-owned)

0.2) OpenAPI split ownership smoke check

```bash
chmod +x deploy/post_deploy_openapi_split_smoke_vps.sh

# SSH key auth
./deploy/post_deploy_openapi_split_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519

# password auth
SSHPASS='YOUR_VPS_PASSWORD' ./deploy/post_deploy_openapi_split_smoke_vps.sh \
  --vps root@207.180.245.156 --password-auth
```

This validates OpenAPI ownership:
- `auth-api` publishes `/api/auth/**` and `/api/driver/device/**`
- `driver-app-api` publishes `/api/driver/**` and `/api/driver-app/**`
- no cross-ownership leakage between both services

0.25) Dynamic driver-policy smoke check

```bash
chmod +x deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh

# SSH key auth + admin credentials
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE'
```

Expected marker:
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

0.26) Dispatch workflow smoke check

```bash
chmod +x deploy/post_deploy_dispatch_workflow_smoke_vps.sh

./deploy/post_deploy_dispatch_workflow_smoke_vps.sh \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE' \
  --driver-username driver1 --driver-password 'REPLACE' \
  --general-dispatch-id 123 \
  --khbl-dispatch-id 456 \
  --fallback-dispatch-id 789 \
  --fallback-linked-template LEGACY_KHBL
```

This validates:
- mobile runtime endpoints respond through the public host:
  - `/api/driver-app/bootstrap`
  - `/api/user-settings`
- admin dispatch-flow resolution matches expected template binding
- `GENERAL` and `KHBL` dispatches do not expose legacy `APPROVED` action paths
- proof-driven transitions still require:
  - `POL` for `LOADING -> LOADED`
  - `POD` for `UNLOADING -> UNLOADED`
- fallback dispatches with invalid/inactive template links resolve back to `GENERAL`

Expected marker:
- `DISPATCH_WORKFLOW_SMOKE_OK`

Live DB inspection helper:

```bash
mysql -u USER -p DB_NAME < deploy/inspect_dispatch_workflow_templates.sql
```

0.3) Full morning release gate runner (recommended)

```bash
chmod +x deploy/prod_morning_release_split_vps.sh

./deploy/prod_morning_release_split_vps.sh \
  --vps root@207.180.245.156 \
  --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE' \
  --driver-username driver1 --driver-password 'REPLACE' \
  --workflow-general-dispatch-id 123 \
  --workflow-khbl-dispatch-id 456 \
  --workflow-fallback-dispatch-id 789 \
  --workflow-fallback-linked-template LEGACY_KHBL \
  --manual-smoke-status pass \
  --deploy-cmd "sudo /opt/sv-tms/deploy/prod_release_split_vps.sh"
```

Expected final marker:
- `PRODUCTION_MORNING_RELEASE_PLAN_OK`

Decision gate:
- default decision is **NO_GO** unless `--manual-smoke-status pass` is provided.

0.4) Post-release stabilization watch (recommended)

```bash
chmod +x deploy/post_release_stabilization_watch_vps.sh

./deploy/post_release_stabilization_watch_vps.sh \
  --vps root@207.180.245.156 \
  --ssh-key ~/.ssh/id_ed25519 \
  --duration-min 60 \
  --interval-sec 60
```

1) Backup and transfer DB:

```
chmod +x deploy/backup_and_transfer_db.sh
./deploy/backup_and_transfer_db.sh --vps ubuntu@1.2.3.4 --ssh-key ~/.ssh/id_rsa --db-name tmsdb --db-user root --db-pass secret
```

This creates a gzipped dump and copies it to `/tmp` on the VPS. To import on the VPS run:

```
ssh -i ~/.ssh/id_rsa ubuntu@1.2.3.4 "gunzip -c /tmp/tmsdb-YYYYMMDD-HHMMSS.sql.gz | mysql -u root -p'
```

2) Deploy backend jar via systemd:

```
chmod +x deploy/deploy_backend.sh
# build locally then run
./deploy/deploy_backend.sh --vps ubuntu@1.2.3.4 --ssh-key ~/.ssh/id_rsa --jar-path tms-backend/target/tms-backend.jar
```

Followups / manual steps on VPS
- Ensure Java (17+) is installed: `sudo apt install openjdk-17-jre` or your preferred JRE.
- Create `/etc/default/tms-backend` with env vars like DB_HOST, DB_USER, DB_PASS, JAVA_OPTS.
- Place nginx config from `nginx_tms_backend.conf.template` into `/etc/nginx/sites-available/` and enable it.

Security notes
- Do not pass DB passwords on shared shells; prefer `~/.my.cnf` or environment files.
- Keep SSH keys secure and restrict access.

3) Split backend + admin UI VPS update with backup and rollback:

```bash
chmod +x deploy/deploy_split_and_admin_ui_to_vps.sh

./deploy/deploy_split_and_admin_ui_to_vps.sh \
  --vps root@207.180.245.156 \
  --ssh-key ~/.ssh/id_ed25519 \
  --remote-base-dir /opt/sv-tms \
  --frontend-reload-service nginx
```

This flow does the following:
- Builds `tms-auth-api` and `tms-driver-app-api` locally and uploads both jars.
- Builds `tms-admin-web-ui` locally and uploads a tarball of the production build.
- Uploads `prod_release_split_vps.sh`, rollback/backup helpers, and split systemd templates to the VPS.
- Runs the split backend release on the VPS with DB backup unless `--skip-remote-db-backup` is used.
- Archives the current live frontend directory before replacing it.
- Reloads nginx after the admin UI update.

Server layout expected by the new scripts:
- Auth app dir: `/opt/tms-auth-api`
- Driver app dir: `/opt/tms-driver-app-api`
- Frontend live dir: `/opt/sv-tms/frontend`
- Release metadata: `/opt/sv-tms/releases`
- Incoming artifacts: `/opt/sv-tms/incoming`
- Shared backend config source: `/opt/sv-tms/backend/application.properties`
- Split service env files: `/etc/default/tms-auth-api` and `/etc/default/tms-driver-app-api`

Rollback:

```bash
ssh -i ~/.ssh/id_ed25519 root@207.180.245.156
sudo /opt/sv-tms/deploy/prod_rollback_vps.sh
```

Notes:
- The combined local helper matches the current split-service VPS topology. Do not use the older `deploy_update_to_vps.sh` monolith helper on a split-production host.
- The split backend release still relies on `/opt/sv-tms/backend/application.properties` for shared Spring config.
- `mysqldump` and `mysql` must be installed on the VPS.
- The rollback script restores the database from the backup manifest created during the release, then restores the backed up backend/frontend directories used by the VPS release scripts.

4) Microservice routing with one public host:

Use `nginx_tms_microservices.conf.template` when `tms-auth-api`,
`tms-driver-app-api`, and `tms-telematics-api` run as separate systemd
services on the same VPS.

Expected local ports:
- `tms-auth-api` → `127.0.0.1:8083`
- `tms-driver-app-api` → `127.0.0.1:8084`
- `tms-telematics-api` → `127.0.0.1:8082`

The nginx template routes these paths to auth:
- `/api/auth/**`
- `/api/driver/device/**`

The nginx template routes these paths to driver-app:
- `/api/driver/**`
- `/api/driver-app/**`
- `/api/public/app-version/**`
- `/ws`
- `/ws-sockjs/**`

The nginx template routes these paths to telematics:
- `/api/public/tracking/**`
- `/tele-ws/**`
- `/tele-ws-sockjs/**`

All other requests currently fall through to `tms-driver-app-api` for mobile compatibility.

5) PostgreSQL-backed telematics:

`tms-telematics-api` is now configured for PostgreSQL as its primary database.

Use `deploy/tms-telematics.env.postgresql.example` as the starting point for
`/etc/default/tms-telematics`.

Important runtime defaults:
- backend compatibility proxy is disabled by default:
  - `TELEMATICS_COMPATIBILITY_PROXY_ENABLED=false`
- telematics should receive tracking traffic directly from nginx
- telematics location history is stored in PostgreSQL with monthly partition maintenance enabled
