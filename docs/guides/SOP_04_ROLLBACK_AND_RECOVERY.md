# SOP 04 - Rollback and Recovery

## Purpose

Return production to last known good state.

## When To Rollback

- health checks fail after deploy
- smoke markers missing
- major user-facing regression

## Rollback Steps

1. Execute rollback script:
```bash
sudo /opt/sv-tms/deploy/prod_rollback_vps.sh
```

2. Restart/reload services:
```bash
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl reload nginx
```

3. Re-check health:
```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

4. Re-run smokes:
```bash
./deploy/post_deploy_microservices_routing_smoke_vps.sh ...
./deploy/post_deploy_openapi_split_smoke_vps.sh ...
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh ...
```

## Recovery Complete Criteria

- both services healthy
- all smoke markers present
- core mobile flow works
