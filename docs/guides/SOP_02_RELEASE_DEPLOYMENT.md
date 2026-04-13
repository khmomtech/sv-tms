# SOP 02 - Release Deployment

## Purpose

Deploy safely with clear go/no-go gates.

## Pre-Deploy

1. Build and compile green.
2. Integration tests green.
3. Backup completed.
4. Rollback script ready.

## Deploy

Use your standard deploy scripts from `deploy/`.

Recommended deploy flow for split production:

```bash
./deploy/deploy_split_and_admin_ui_to_vps.sh \
  --vps root@YOUR_VPS \
  --ssh-key ~/.ssh/id_ed25519
```

Then run the mandatory smoke gates:

```bash
./deploy/post_deploy_microservices_routing_smoke_vps.sh \
  --vps root@YOUR_VPS \
  --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz

./deploy/post_deploy_openapi_split_smoke_vps.sh \
  --vps root@YOUR_VPS \
  --ssh-key ~/.ssh/id_ed25519

./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh \
  --vps root@YOUR_VPS \
  --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE'
```

Important:
- If manual mobile smoke is not `pass`, decision stays **NO_GO**.

## Post-Deploy Validation (Mandatory Order)

1. Service health checks.
2. Routing smoke script.
3. OpenAPI split smoke script.
4. Dynamic driver-policy smoke script.

Additional production checks (required for web admin + realtime):

```bash
# auth through frontend domain should hit split auth-api and return app-layer response
curl -s -o /tmp/auth.out -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' --data '{}' \
  https://svtms.svtrucking.biz/api/auth/login

# SockJS info should be 200 JSON from driver-app websocket endpoint
curl -i 'https://svtms.svtrucking.biz/ws-sockjs/info?token=TEST'
```

If login errors include SQL unknown column in auth logs, stop and fix schema drift before go-live:

```bash
journalctl -u tms-auth-api -n 200 --no-pager | grep -i "Unknown column"
mysql -uroot -prootpass -D svlogistics_tms_db \
  -e 'ALTER TABLE customers ADD COLUMN device_token VARCHAR(512) NULL;'
```

## Release Acceptance Rule

Release is accepted only if all markers appear:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

If missing, stop and execute rollback SOP 04.
