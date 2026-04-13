# infra/ — Infrastructure Reference

Single source of truth for the SV-TMS production infrastructure.

---

## Directory Layout

```
infra/
├── docker-compose.prod.yml          # Production stack (all services)
├── docker-compose.build-override.yml# Overrides registry images → build from source on VPS
├── .env                             # Production secrets (gitignored, never commit)
├── .env.example                     # Template — copy to .env and fill values
├── nginx/
│   └── site.conf                    # Reverse proxy, SSL, rate limiting
├── monitoring/
│   ├── prometheus.yml               # Scrape targets
│   ├── alert_rules.yml              # Alert conditions
│   ├── alertmanager.yml             # Alert routing (email/Slack)
│   └── grafana/
│       ├── provisioning/            # Auto-provisioned datasources + dashboards
│       └── dashboards/              # platform-overview.json
├── scripts/
│   ├── backup_stack.sh              # Full backup: DBs + uploads + spool
│   ├── restore_stack.sh             # Full restore from backup archive
│   ├── verify_backup.sh             # Checksum verification of backup
│   ├── sync_backups_offsite.sh      # Replicate backups to remote storage
│   ├── prune_backups.sh             # Remove old backups
│   ├── kafka_init_topics.sh         # Create Kafka topics (run once on fresh VPS)
│   ├── kafka_reassign_partitions.sh # Kafka partition rebalancing
│   ├── preflight_prod.sh            # Pre-deploy health checks
│   ├── post_deploy_smoke.sh         # Post-deploy smoke tests
│   └── deploy_stack.sh              # Stack start/restart helper
├── systemd/
│   ├── svtms-backup.service/.timer         # Daily full backup
│   ├── svtms-backup-offsite.service/.timer # Weekly offsite sync
│   ├── svtms-certbot-renew.service/.timer  # SSL cert auto-renewal
│   └── svtms-restore-drill.service         # Monthly restore test
└── ansible/
    ├── playbook.yml                 # VPS provisioning playbook
    ├── inventory.ini                # Target hosts
    └── README.md                   # Ansible usage guide
```

---

## Production Stack

Compose file: `docker-compose.prod.yml`

| Service | Image | Port (internal) | DB |
|---|---|---|---|
| `core-api` | svtms-core-api | 8080 | MySQL + MongoDB + Redis + Kafka |
| `auth-api` | svtms-auth-api | 8083 | MySQL + Redis |
| `telematics-api` | svtms-telematics-api | 8082 | PostgreSQL + MongoDB |
| `driver-app-api` | svtms-driver-app-api | 8084 | MySQL |
| `safety-api` | svtms-safety-api | 8087 | MySQL |
| `message-api` | svtms-message-api | 8088 | H2 (file) + Kafka |
| `api-gateway` | svtms-api-gateway | 8086 | — |
| `admin-web-ui` | svtms-admin-web-ui | 80 | — |
| `nginx` | nginx:1.27-alpine | 80, 443 | — |
| `mysql` | mysql:8.0 | 3306 | svlogistics_tms_db |
| `postgres` | postgres:16-alpine | 5432 | svlogistics_telematics |
| `mongo` | mongo:6.0 | 27017 | — |
| `redis` | redis:7-alpine | 6379 | — |
| `kafka-1/2/3` | cp-kafka:7.6.0 | 9092 | — |
| `prometheus` | prom/prometheus | 9090 (localhost only) | — |
| `grafana` | grafana | 3000 (localhost only) | — |

**Flyway ownership:** `core-api` is the sole Flyway migration owner (`SPRING_FLYWAY_ENABLED=true`).
All other services have it disabled. Never enable Flyway on any other service.

---

## Deploy

```bash
# Full deploy from your local machine (rsync + build on VPS + start)
bash DEPLOY_TO_VPS.sh

# Rebuild and restart one service only
ssh -i infra/deploy_key root@207.180.245.156 "
  cd /opt/sv-tms/repo/infra
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    build {service} && \
  docker compose -f docker-compose.prod.yml -f docker-compose.build-override.yml \
    up -d {service}
"

# Watch logs
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f"
```

**VPS details:**
- Host: `207.180.245.156`
- App root: `/opt/sv-tms/repo/`
- Data volumes: `/srv/svtms/{mysql,postgres,redis,mongo,kafka-*,uploads,spool}`
- Swap: 4 GB (required — Maven builds consume up to 1 GB heap)

---

## First-Time VPS Setup

`DEPLOY_TO_VPS.sh` handles everything automatically:
1. Installs Docker + Docker Compose plugin if missing
2. Creates 4 GB swapfile if no swap exists
3. Creates data directories at `/srv/svtms/`
4. Pulls base images (mysql, redis, kafka, nginx…)
5. Builds app images sequentially (prevents OOM)
6. Starts infrastructure, waits 60 s
7. Starts application services
8. Obtains SSL cert via certbot (port 80 must be open)
9. Starts nginx

After first deploy, install systemd timers:
```bash
ssh -i infra/deploy_key root@207.180.245.156
cp /opt/sv-tms/repo/infra/systemd/* /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now svtms-backup.timer
systemctl enable --now svtms-backup-offsite.timer
systemctl enable --now svtms-certbot-renew.timer
```

Initialize Kafka topics (once):
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "bash /opt/sv-tms/repo/infra/scripts/kafka_init_topics.sh"
```

---

## Secrets

`.env` is **gitignored** — never commit it. On fresh setup:
```bash
cp infra/.env.example infra/.env
# Fill in all values — especially:
#   MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD
#   JWT_ACCESS_SECRET, JWT_REFRESH_SECRET  (min 64-char random strings)
#   MAPS_API_KEY  (Google Maps API key)
```

Firebase credentials (upload manually — not in .env):
```bash
scp -i infra/deploy_key firebase-service-account.json \
  root@207.180.245.156:/opt/sv-tms/secrets/firebase-service-account.json
```

---

## Backup & Restore

```bash
# Manual backup (also runs daily via systemd timer)
ssh -i infra/deploy_key root@207.180.245.156 \
  "bash /opt/sv-tms/repo/infra/scripts/backup_stack.sh"

# Restore from archive
ssh -i infra/deploy_key root@207.180.245.156 \
  "bash /opt/sv-tms/repo/infra/scripts/restore_stack.sh /backups/svtms-backup-{date}.tar.gz"
```

Backups include: MySQL dump, PostgreSQL dump, MongoDB dump, Redis RDB, uploads, spool.

---

## Monitoring

| Dashboard | URL |
|---|---|
| Grafana (platform overview) | `https://svtms.svtrucking.biz/grafana` |
| Prometheus (SSH tunnel only) | `http://localhost:9090` |

Alerts in `monitoring/alert_rules.yml`: service down, disk >80%, spool growth, high memory.

---

## Pre/Post Deploy Checks

```bash
# Before deploy — verify SSH, .env, disk, DB
bash infra/scripts/preflight_prod.sh

# After deploy — verify all services return UP, SSL valid
bash infra/scripts/post_deploy_smoke.sh
```
