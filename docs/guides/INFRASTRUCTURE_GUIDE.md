# Infrastructure Guide (Kid-Friendly)

Think of production like a house:
- `nginx` is the front door.
- `tms-auth-api` is the room that checks who you are.
- `tms-driver-app-api` is the room that does driver app work.

## Current Production Shape

- Auth API: `127.0.0.1:8083`
- Driver App API: `127.0.0.1:8084`
- Ingress: `nginx`

## Who Owns Which URL

### Auth service owns:
- `/api/auth/**`
- `/api/driver/device/**`

### Driver-app service owns:
- `/api/driver/**`
- `/api/driver-app/**`
- `/api/public/app-version/**`
- `/ws`
- `/ws-sockjs/**`

If a route goes to the wrong service, app behavior breaks.

## Service Names (systemd)

- `tms-auth-api`
- `tms-driver-app-api`
- `nginx`

## Health Checks

```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
systemctl is-active tms-auth-api tms-driver-app-api nginx
```

All must be healthy/active.

## Golden Deploy Rule

After every deploy, always run:

```bash
./deploy/post_deploy_microservices_routing_smoke_vps.sh ...
./deploy/post_deploy_openapi_split_smoke_vps.sh ...
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh ...
```

Required success markers:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

No marker = do not accept deploy.

## Files That Matter Most

- nginx template:
  - `/Users/sotheakh/Documents/develop/sv-tms/deploy/nginx_tms_microservices.conf.template`
- service templates:
  - `/Users/sotheakh/Documents/develop/sv-tms/deploy/tms-auth-api.service.template`
  - `/Users/sotheakh/Documents/develop/sv-tms/deploy/tms-driver-app-api.service.template`
- env examples:
  - `/Users/sotheakh/Documents/develop/sv-tms/deploy/tms-auth-api.env.example`
  - `/Users/sotheakh/Documents/develop/sv-tms/deploy/tms-driver-app-api.env.example`
