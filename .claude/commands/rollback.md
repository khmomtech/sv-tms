---
name: rollback
description: DevOps — roll back a service on the production VPS to its previous image
---

Roll back the following service on the production VPS: $ARGUMENTS

Steps:
1. SSH to VPS and list the last two images for the service:
   ```bash
   ssh -i infra/deploy_key root@207.180.245.156 \
     "docker images {service} --format '{{.Repository}}:{{.Tag}} {{.CreatedAt}}' | head -5"
   ```
2. Identify the previous image tag or ID.
3. Stop the current container:
   ```bash
   ssh -i infra/deploy_key root@207.180.245.156 "
     cd /opt/sv-tms/repo/infra
     docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml stop {service}
   "
   ```
4. Start the previous image:
   ```bash
   ssh -i infra/deploy_key root@207.180.245.156 "
     docker tag {previous-image-id} {service}:latest
     cd /opt/sv-tms/repo/infra
     docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml up -d {service}
   "
   ```
5. Wait 15 seconds and check health:
   ```bash
   ssh -i infra/deploy_key root@207.180.245.156 "
     docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
       -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml ps {service}
   "
   ```
6. Report: which image is now running, health status, any errors in the last 20 log lines.

**Note:** If this is a database migration rollback, check if a `U{version}__*_rollback.sql` file exists in `tms-core-api/src/main/resources/db/migration/` and run it manually before rolling back the service image.
