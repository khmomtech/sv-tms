# Ongoing Maintenance Guide (Kid-Friendly)

Think of maintenance like caring for a car:
- check engine lights every day,
- service it every week,
- fix small issues before they become big ones.

## Daily Checks (10-15 minutes)

```bash
systemctl is-active tms-auth-api tms-driver-app-api nginx
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

Then review logs:

```bash
journalctl -u tms-auth-api -n 200 --no-pager
journalctl -u tms-driver-app-api -n 200 --no-pager
tail -n 200 /var/log/nginx/error.log
```

## After Every Deploy

Run in this order:

1. health checks
2. routing smoke
3. OpenAPI split smoke
4. dynamic driver-policy smoke

```bash
./deploy/post_deploy_microservices_routing_smoke_vps.sh ...
./deploy/post_deploy_openapi_split_smoke_vps.sh ...
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh ...
```

Deployment is failed if any marker is missing:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

## Weekly Checks

- Confirm backups are present and recent.
- Confirm disk has free space.
- Confirm nginx config still matches split route ownership.
- Re-run all smoke scripts even without a release.

## Incident Quick Triage

### Symptom: login fails (`/api/auth/**`)
1. `systemctl status tms-auth-api`
2. `curl http://127.0.0.1:8083/actuator/health`
3. `nginx -t`

### Symptom: driver app APIs fail (`/api/driver/**`, `/api/driver-app/**`)
1. `systemctl status tms-driver-app-api`
2. `curl http://127.0.0.1:8084/actuator/health`
3. `nginx -t`

### Symptom: websocket fails (`/ws-sockjs/**`)
1. check nginx websocket location
2. check driver-app logs
3. run routing smoke script

## Safe Rollback (If Needed)

```bash
sudo /opt/sv-tms/deploy/prod_rollback_vps.sh
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl reload nginx
```

## Source Of Truth

For detailed ops commands always use:
- `/Users/sotheakh/Documents/develop/sv-tms/docs/deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md`
- `/Users/sotheakh/Documents/develop/sv-tms/deploy/README_DEPLOY.md`
- `/Users/sotheakh/Documents/develop/sv-tms/deploy/DEPLOYMENT_HANDBOOK.md`
