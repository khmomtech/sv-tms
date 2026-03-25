# SV-TMS Deployment & Ongoing Operations Handbook

Purpose: a concise, actionable guide for deploying and operating the SV-TMS services (auth-api, driver-app-api, telematics, frontend, WebSockets). Keep this with repo ops notes and update on each change.

**Scope**: `tms-auth-api`, `tms-driver-app-api`, `tms-telematics-api`, legacy `tms-backend`, frontend (`tms-frontend`), reverse proxy (nginx), uploads folder, and WebSocket/STOMP (SockJS).

**Quick refs**
- Nginx sample proxy for SockJS: [deploy/nginx-ws-sockjs.conf](deploy/nginx-ws-sockjs.conf)
- Driver app security config: [tms-driver-app-api/src/main/java/com/svtrucking/logistics/driverapp/DriverAppApiSecurityConfig.java](tms-driver-app-api/src/main/java/com/svtrucking/logistics/driverapp/DriverAppApiSecurityConfig.java)
- Morning release gate runner: [deploy/prod_morning_release_split_vps.sh](deploy/prod_morning_release_split_vps.sh)
- Rollout checklist: [deploy/DISPATCH_WORKFLOW_ROLLOUT_CHECKLIST.md](deploy/DISPATCH_WORKFLOW_ROLLOUT_CHECKLIST.md)

**Prerequisites**
- SSH access to VPS (root or sudo user).
- Code/artifacts available at `/opt/sv-tms` (or the host-specific path).
- Java 17+ and `./mvnw` for local builds, or Docker/Docker Compose for container deployments.
- Nginx running as reverse proxy (port 80/443) with certs if serving HTTPS.
- Secrets managed securely (do NOT commit service accounts or secrets into git). Example service-account path used by backend: `/opt/sv-tms/backend/firebase`.

**Pre-deploy checklist**
- [ ] Backup DB and uploads (see Backups section).
- [ ] Verify health of dependent services (MySQL, Redis).
- [ ] Confirm maintenance window and notify users if needed.
- [ ] Acquire valid JWT / test tokens for smoke tests.

**Single-command morning release flow (split)**
```bash
chmod +x deploy/prod_morning_release_split_vps.sh
./deploy/prod_morning_release_split_vps.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519 \
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
Success marker: `PRODUCTION_MORNING_RELEASE_PLAN_OK`
Default decision policy: `NO_GO` unless manual mobile smoke status is `pass`.

**Deploy variants**
- Systemd/jar: start `tms-auth-api`, `tms-driver-app-api`, and `tms-telematics-api` via separate `systemctl` units.
- Docker Compose: put `docker-compose.yml` in `/opt/sv-tms` and run `docker compose up -d --build`.

**Standard deploy (Docker Compose)**
1. SSH to VPS.
2. Pull latest code/artifacts or update image tags.
3. From `/opt/sv-tms`:
```bash
git pull origin main  # if using repo on host
# or update images: docker compose pull
# then build/start
docker compose up -d --build
docker compose ps
```
4. Verify services are up and listening on their internal ports:
```bash
ss -tlnp | egrep ":8083|:8084|:8082|:80|:443"
curl -sS http://127.0.0.1:8083/actuator/health
curl -sS http://127.0.0.1:8084/actuator/health
```

**Standard deploy (systemd / jar)**
1. Upload new jars to the relevant service directories.
2. Restart services:
```bash
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl restart tms-telematics
sudo systemctl status tms-driver-app-api -l
```
3. Tail logs:
```bash
sudo journalctl -u tms-auth-api -f
sudo journalctl -u tms-driver-app-api -f
sudo journalctl -u tms-telematics -f
```

**Nginx (reverse proxy) — ensure WebSocket passthrough**
- Place a site file under `/etc/nginx/sites-enabled/` (named e.g. `svtms-ws.conf`) with dedicated `/ws` and `/ws-sockjs/` locations that route to `tms-driver-app-api` and set:
  - `proxy_http_version 1.1`
  - `proxy_set_header Upgrade $http_upgrade;`
  - `proxy_set_header Connection $connection_upgrade;` (use a `map` for $connection_upgrade)
  - `proxy_read_timeout 3600s`

- Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```
- Reference sample: [deploy/nginx-ws-sockjs.conf](deploy/nginx-ws-sockjs.conf)

**WebSocket / SockJS verification**
- SockJS `info` endpoint should return JSON 200:
```bash
curl -i "https://svtms.svtrucking.biz/ws-sockjs/info?token=REPLACE"
```
- Raw websocket handshake check (should return `101 Switching Protocols` when successful):
```bash
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" "https://svtms.svtrucking.biz/ws-sockjs/ID/SESSION/websocket?token=REPLACE"
```
- `wscat` test:
```bash
npm i -g wscat
wscat -c "wss://svtms.svtrucking.biz/ws-sockjs/ID/SESSION/websocket?token=REPLACE"
```

Common symptom: `Error during WebSocket handshake: Unexpected response code: 200` or `405 Not Allowed` on `xhr_streaming`
- Likely cause: nginx forwarded to frontend fallback (`index.html`) or backend not reachable (connection refused). Fixes:
  - Ensure `tms-driver-app-api` is listening on the proxied address (`127.0.0.1:8084`) and is running.
  - Add dedicated `/ws` and `/ws-sockjs/` proxy locations in nginx and allow POST.
  - Ensure `proxy_http_version 1.1` and proper `Upgrade`/`Connection` headers.

**Split routing**
- `/api/auth/**` -> `tms-auth-api`
- `/api/driver/device/**` -> `tms-auth-api`
- `/api/driver/**` -> `tms-driver-app-api`
- `/api/driver-app/**` -> `tms-driver-app-api`
- `/api/public/app-version/**` -> `tms-driver-app-api`
- `/ws` and `/ws-sockjs/**` -> `tms-driver-app-api`
- `/tele-ws/**` and `/tele-ws-sockjs/**` -> `tms-telematics-api`

**Health checks & smoke tests**
- Auth and driver-app health endpoints: `GET /actuator/health`
- Smoke test script (run after deploy):
```bash
# auth and driver-app
curl -fsS https://svtms.svtrucking.biz/actuator/health || true
# ws-sockjs info
curl -fsS "https://svtms.svtrucking.biz/ws-sockjs/info?token=TEST_TOKEN" | jq . || true
```
- Recommended split-routing smoke check (VPS):
```bash
chmod +x deploy/post_deploy_microservices_routing_smoke_vps.sh
./deploy/post_deploy_microservices_routing_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz
```
- Expected result: `MICROSERVICE_ROUTING_SMOKE_OK`
- OpenAPI ownership smoke check (VPS):
```bash
chmod +x deploy/post_deploy_openapi_split_smoke_vps.sh
./deploy/post_deploy_openapi_split_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519
```
- Expected result: `OPENAPI_SPLIT_SMOKE_OK`
- Dynamic driver policy smoke check (VPS):
```bash
chmod +x deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
  --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE'
```
- Expected result: `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
- Dispatch workflow smoke check (recommended in staging/pilot before production):
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
- Expected result: `DISPATCH_WORKFLOW_SMOKE_OK`
- DB inspection helper:
```bash
mysql -u USER -p DB_NAME < deploy/inspect_dispatch_workflow_templates.sql
```
- Review these rollout invariants before release:
  - blank or null `loading_type_code` resolves to `GENERAL`
  - `GENERAL` and `KHBL` no longer expose `APPROVED`
  - `LOADING -> LOADED` requires `POL`
  - `UNLOADING -> UNLOADED` requires `POD`
  - KHBL driver actions do not directly own loading-control transitions

**Rolling update / zero downtime**
- Docker: use separate compose files for canary/blue-green and update service by bringing up new tasks and shifting traffic at load balancer level.
- Systemd: short downtime unavoidable unless using a load balancer/secondary host.

**Rollback**
- Docker: `docker compose up -d backend@previous` (use image tags) or redeploy previous `docker-compose.yml`/image tag.
- Jar: restart `tms-backend` with the previous jar and verify health.

**Database migrations**
- If your project uses Flyway or Liquibase, run migrations prior to switching traffic. Typical flow:
  1. Run migration in a maintenance window or on a replica.
  2. Confirm success and run smoke tests.

**Backups**
- MySQL dump (daily):
```bash
mysqldump -u root -p DB_NAME | gzip > /opt/sv-tms/backups/mysql-$(date +%F).sql.gz
# rotate older than 14 days
find /opt/sv-tms/backups -type f -mtime +14 -delete
```
- Uploads folder: `/opt/sv-tms/uploads` — snapshot with rsync to backup host or S3.

**Monitoring & logs**
- Nginx logs: `/var/log/nginx/access.log` and `error.log`.
- Backend logs: `journalctl -u tms-backend -f` or `/var/log/tms-backend.log`.
- Set up alerting for: high 5xx rate (nginx), backend down, disk usage > 80%, DB unavailable.

**Runbook: WebSocket handshake failing**
1. Confirm driver-app-api reachable:
```bash
ss -tlnp | grep 8084
curl -v http://127.0.0.1:8084/ws-sockjs/info?token=TEST
```
2. If connection refused, start `tms-driver-app-api` (`docker compose up -d` or `systemctl start tms-driver-app-api`).
3. If `info` returns 200 but `xhr_streaming` returns 405, check nginx maps and location blocks; ensure POST is proxied to driver-app-api (not served by static fallback).
4. Check nginx error log for `connect() failed (111)` meaning driver-app-api is down.
5. Verify the driver-app security config permits `/ws` and `/ws-sockjs/**`.

**Common commands**
- Start/restart microservices (systemd):
```bash
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl restart tms-telematics
```
- Docker compose:
```bash
cd /opt/sv-tms
docker compose up -d --build
docker compose logs -f auth-api driver-app-api telematics
```
- Nginx reload and test:
```bash
sudo nginx -t
sudo systemctl reload nginx
sudo tail -n 200 /var/log/nginx/error.log
```

**Maintenance tasks**
- Rotate logs, prune docker images, run `apt` updates during maintenance windows.
- Periodically verify SSL cert expiry and renew via certbot.

**Contacts**
- Primary on-call: ops@example.com
- Backend owner: `@backend-dev`
- Frontend owner: `@frontend-dev`

---
Update this handbook when any of the following change: ports, service names, proxy rules, or storage paths. For automation requests (CI/CD, Ansible, systemd templates), mark `deploy/` tasks and we can add scripts next.
