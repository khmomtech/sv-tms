---
description: DevOps and deployment conventions — VPS, Docker, monitoring, rollback
---

# DevOps Conventions

## Deployment

```bash
# Full deploy (build + start all services)
bash DEPLOY_TO_VPS.sh

# Push only config/env changes (skip build)
scp -i infra/deploy_key infra/.env root@207.180.245.156:/opt/sv-tms/repo/infra/.env

# Rebuild and restart one service on VPS
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    build {service} && \
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    up -d {service}
"
```

## Service Names (docker compose)

| Compose service | Module |
|---|---|
| `core-api` | tms-core-api |
| `auth-api` | tms-auth-api |
| `driver-app-api` | tms-driver-app-api |
| `telematics-api` | tms-telematics-api |
| `safety-api` | tms-safety-api |
| `message-api` | tms-message-api |
| `api-gateway` | api-gateway |
| `admin-web-ui` | tms-admin-web-ui |

## Health Checks

```bash
# Check all containers
/deploy-status

# Individual service health
curl https://svtms.svtrucking.biz/api/actuator/health

# Watch live logs
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f"
```

## Rollback

Use `/rollback <service>` to roll back a service to its previous image.

Manual rollback:
```bash
ssh -i infra/deploy_key root@207.180.245.156 "
  docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
    -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml \
    stop {service}
  docker tag {service}:previous {service}:latest
  docker compose ... up -d {service}
"
```

## SSL / nginx

- Certbot auto-renews via cron on the VPS.
- If nginx fails to start: check that `/etc/letsencrypt/live/svtms.svtrucking.biz/` exists.
- nginx config: `infra/nginx/site.conf`.

## Monitoring

- Grafana: `https://svtms.svtrucking.biz/grafana`
- Prometheus: internal scrape at `:9090` (not public)
- Node exporter, container metrics collected automatically.

## VPS Specs

- Host: `207.180.245.156`
- SSH: `ssh -i infra/deploy_key root@207.180.245.156`
- App root: `/opt/sv-tms/repo/`
- Data volumes: `/srv/svtms/{mysql,postgres,redis,mongo,kafka-*}`
- Swap: 4 GB at `/swapfile` (required for Maven builds)
