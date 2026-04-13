---
name: deploy-status
description: Check health of all services on the production VPS
---

Check the health of all running services on the production VPS at `207.180.245.156`.

Run:
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml ps"
```

Then for any service that is not `running (healthy)`, check its recent logs:
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs --tail=50 {service}"
```

Report:
- Which services are healthy
- Which services are unhealthy or stopped
- Root cause of any failures from the log output
- Recommended fix action
