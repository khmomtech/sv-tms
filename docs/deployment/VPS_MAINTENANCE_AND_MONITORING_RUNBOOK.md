# VPS Maintenance And Monitoring Runbook (Split Microservices)

This runbook is split-only and defines the production operations contract for `sv-tms` on VPS.

Docs hub:
- `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/INFRASTRUCTURE_GUIDE.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/ONGOING_MAINTENANCE_GUIDE.md`

Legacy note: monolith-first procedures (`svtms-backend` as primary API runtime) are deprecated for this runbook and should not be used for routine deploy or maintenance.

## Current Production Shape

- Host type: single VPS with systemd services and nginx ingress
- Auth service: `tms-auth-api` on `127.0.0.1:8083`
- Driver app service: `tms-driver-app-api` on `127.0.0.1:8084`
- Frontend host: `nginx`
- Public frontend: `https://svtms.svtrucking.biz`
- Public API ingress: `https://svtmsapi.svtrucking.biz`

## Route Ownership Contract

- Auth-owned:
  - `/api/auth/**`
  - `/api/driver/device/**`
- Driver-app-owned:
  - `/api/driver/**`
  - `/api/driver-app/**`
  - `/api/public/app-version/**`
  - `/ws`
  - `/ws-sockjs/**`

Deploy is considered invalid if this ownership contract is broken.

## Live Paths On VPS

- Nginx site config: `/etc/nginx/sites-available/svtms`
- Release backups: `/opt/sv-tms/backups`
- Release manifests: `/opt/sv-tms/releases`
- Deploy scripts path: `/opt/sv-tms/deploy` (on VPS), `deploy/` (repo)

## Services To Monitor

- `systemctl status tms-auth-api`
- `systemctl status tms-driver-app-api`
- `systemctl status nginx`

Expected local health checks:

- `curl -s http://127.0.0.1:8083/actuator/health`
- `curl -s http://127.0.0.1:8084/actuator/health`

Expected public probes:

- `curl -I -s https://svtmsapi.svtrucking.biz/api/auth/health || true`
- `curl -I -s https://svtmsapi.svtrucking.biz/api/driver-app/home-layout || true`
- `curl -I -s https://svtms.svtrucking.biz/`

## Standard Log Checks

- Auth journal:
  - `journalctl -u tms-auth-api -n 200 --no-pager`
  - `journalctl -u tms-auth-api -f`
- Driver app journal:
  - `journalctl -u tms-driver-app-api -n 200 --no-pager`
  - `journalctl -u tms-driver-app-api -f`
- Nginx logs:
  - `tail -n 200 /var/log/nginx/error.log`
  - `tail -n 200 /var/log/nginx/access.log`

## Deploy References

Primary deploy references:

- [deploy/README_DEPLOY.md](/Users/sotheakh/Documents/develop/sv-tms/deploy/README_DEPLOY.md)
- [deploy/DEPLOYMENT_HANDBOOK.md](/Users/sotheakh/Documents/develop/sv-tms/deploy/DEPLOYMENT_HANDBOOK.md)

## Required Post-Deploy Verification Order

Run in this exact order:

1. Service health checks
2. Routing smoke check
3. OpenAPI split ownership smoke check
4. Dynamic driver-policy smoke check

### 1) Service Health Checks

```bash
systemctl is-active tms-auth-api tms-driver-app-api nginx
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

### 2) Routing Smoke Check

```bash
chmod +x deploy/post_deploy_microservices_routing_smoke_vps.sh
./deploy/post_deploy_microservices_routing_smoke_vps.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtmsapi.svtrucking.biz
```

Must contain success marker:

- `MICROSERVICE_ROUTING_SMOKE_OK`

### 3) OpenAPI Split Ownership Smoke Check

```bash
chmod +x deploy/post_deploy_openapi_split_smoke_vps.sh
./deploy/post_deploy_openapi_split_smoke_vps.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519
```

Must contain success marker:

- `OPENAPI_SPLIT_SMOKE_OK`

### 4) Dynamic Driver-Policy Smoke Check

```bash
chmod +x deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtmsapi.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE'
```

Must contain success marker:

- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

### Deploy Failure Criteria

Treat deploy as failed if any of the following occurs:

- `tms-auth-api` or `tms-driver-app-api` health endpoint is not `UP`
- routing smoke output does not contain `MICROSERVICE_ROUTING_SMOKE_OK`
- OpenAPI smoke output does not contain `OPENAPI_SPLIT_SMOKE_OK`
- dynamic policy smoke output does not contain `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
- nginx config test fails (`nginx -t`)

## Recovery / Rollback

Release rollback:

```bash
sudo /opt/sv-tms/deploy/prod_rollback_vps.sh
```

Immediate service-level rollback actions:

```bash
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl reload nginx
```

Manual DB restore from gzip dump:

```bash
gunzip -c /path/to/backup.sql.gz | mysql -uroot -prootpass svlogistics_tms_db
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
```

## Routing Incident Triage

| Symptom | Likely Owner | First 3 Commands To Confirm | Rollback Action |
|---|---|---|---|
| `/api/auth/*` returns 404/502 | auth-api or nginx route map | `systemctl status tms-auth-api`; `curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8083/actuator/health`; `nginx -t` | restart `tms-auth-api`; if still failing, rollback release and reload nginx |
| `/api/driver/*` or `/api/driver-app/*` returns 404/502 | driver-app-api or nginx route map | `systemctl status tms-driver-app-api`; `curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8084/actuator/health`; `nginx -t` | restart `tms-driver-app-api`; if still failing, rollback release and reload nginx |
| `/ws-sockjs/*` handshake fails, 405, or serves HTML | nginx websocket location or driver-app-api | `curl -sv "https://svtmsapi.svtrucking.biz/ws-sockjs/info?token=TEST"`; `tail -n 200 /var/log/nginx/error.log`; `journalctl -u tms-driver-app-api -n 200 --no-pager` | reload nginx with validated ws routes; restart `tms-driver-app-api`; rollback if regression introduced |
| OpenAPI split check fails (`OPENAPI_SPLIT_SMOKE_OK` missing) | wrong service build/routing ownership leak | `curl -s http://127.0.0.1:8083/v3/api-docs | head`; `curl -s http://127.0.0.1:8084/v3/api-docs | head`; rerun `post_deploy_openapi_split_smoke_vps.sh` | rollback service(s) to previous known-good build; rerun both smoke scripts |
| Dynamic policy check fails (`DYNAMIC_DRIVER_POLICY_SMOKE_OK` missing) | auth token path, admin setting ACL, or policy guard regression | `curl -s -o /tmp/login.out -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' --data '{"username":"superadmin","password":"REPLACE"}' https://svtmsapi.svtrucking.biz/api/auth/login`; `journalctl -u tms-driver-app-api -n 200 --no-pager`; rerun `post_deploy_dynamic_driver_policy_smoke_vps.sh` | rollback service(s) to previous known-good build; rerun all smoke scripts |

## Known Production Fixes (March 11, 2026)

### A) Web login shows "Invalid username or password" but credentials are correct

Symptom:
- Web login page rejects `superadmin` with generic invalid credentials.

Actual root cause:
- DB schema drift on production.
- Missing column `customers.device_token`.
- Auth logs show SQL error:
  - `Unknown column 'c1_0.device_token' in 'field list'`

Confirm:
```bash
journalctl -u tms-auth-api -n 200 --no-pager | grep -i "Unknown column"
mysql -uroot -prootpass -D svlogistics_tms_db -e 'SHOW COLUMNS FROM customers LIKE "device_token";'
```

Fix:
```bash
mysql -uroot -prootpass -D svlogistics_tms_db \
  -e 'ALTER TABLE customers ADD COLUMN device_token VARCHAR(512) NULL;'
```

Re-check:
```bash
curl -s -o /tmp/login.out -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  --data '{"username":"superadmin","password":"WRONG_PASSWORD"}' \
  https://svtms.svtrucking.biz/api/auth/login
```
- Expected after DB fix: no SQL error in logs; normal auth result (401 for wrong password, 200 for correct password).

### B) WebSocket fails (`/ws-sockjs` handshake 400, `xhr_send` 404)

Symptom:
- Browser console shows websocket handshake failure on `wss://svtms.svtrucking.biz/ws-sockjs/...`
- Follow-up SockJS fallback hits 404 on `xhr_send`.

Actual root cause:
- `svtms` nginx site was still routing websocket paths to old monolith `127.0.0.1:8080`.
- Missing upgrade headers on `/ws-sockjs/`.

Required nginx mapping for `svtms.svtrucking.biz`:
- `/ws/` -> `127.0.0.1:8084`
- `/ws-sockjs/` -> `127.0.0.1:8084`

Validate:
```bash
grep -n 'location /ws/\|location /ws-sockjs/\|proxy_pass http://127.0.0.1:8084' /etc/nginx/sites-available/svtms
curl -i 'https://svtms.svtrucking.biz/ws-sockjs/info?token=TEST'
```

Expected:
- `ws-sockjs/info` returns HTTP 200 JSON (not HTML 404 page).
- Handshake failures should become auth-level (`401`) when token is invalid, not route-level 400/404.

## Daily Monitoring Checklist

1. Confirm `systemctl` status for `tms-auth-api`, `tms-driver-app-api`, `nginx`.
2. Confirm both local health endpoints return `UP`.
3. Confirm API ingress and frontend root return expected status.
4. Review auth and driver journals for startup failures or DB errors.
5. Review nginx error log for upstream connectivity or route mismatches.
6. Confirm disk headroom for dumps and release backups.
7. Confirm recent backups exist under `/opt/sv-tms/backups`.
8. Confirm uploads backup exists and is fresh (`/opt/sv-tms/uploads` or configured upload volume), then verify restore path in staging for POL/POD files.

## Post-Release Stabilization Watch (60 Min)

Use this command from repo root:

```bash
./deploy/post_release_stabilization_watch_vps.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519 \
  --duration-min 60 --interval-sec 60
```

This produces a timestamped report in `deploy/reports/` for handover evidence.

## Weekly Maintenance Checklist

1. Re-run all smoke scripts after any deploy or nginx change.
2. Review `/opt/sv-tms/backups` growth and retention.
3. Review release manifests under `/opt/sv-tms/releases`.
4. Validate nginx config still matches split route ownership.
5. Confirm OpenAPI split ownership check passes on current running version.

## Security Notes

- Use SSH key authentication for routine maintenance.
- Rotate root password if exposed in shell history/chat.
- Avoid reusable shell history containing DB credentials.
- Keep `/etc/default/tms-auth-api` and `/etc/default/tms-driver-app-api` root-readable only.
