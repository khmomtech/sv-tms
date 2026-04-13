# CLAUDE.md — SV-TMS Collaboration Guide

SV-TMS is a monorepo Transport Management System for SV Trucking (Java 21 + Spring Boot 3 + Angular 17+ + Flutter 3.5+).

---

## Module Map

```
sv-tms/
├── tms-core-api/          # Main business logic (port 8080) — MySQL + MongoDB + Kafka
├── tms-auth-api/          # Authentication & JWT (port 8083) — MySQL + Redis
├── tms-telematics-api/    # GPS / live tracking (port 8082) — PostgreSQL + MongoDB
├── tms-driver-app-api/    # Driver mobile backend (port 8084) — MySQL
├── tms-safety-api/        # Safety checks (port 8087) — MySQL
├── tms-message-api/       # Messaging / notifications (port 8088) — H2 + Kafka
├── api-gateway/           # Spring Cloud Gateway (port 8086)
├── tms-backend-shared/    # Shared DTOs — no standalone service
├── tms-admin-web-ui/      # Angular admin dashboard (port 4200 dev)
├── infra/                 # docker-compose.prod.yml, .env, nginx, monitoring
└── tms_driver_app/        # Flutter driver app
```

---

## Rules (modular — loaded by role)

@.claude/rules/ports.md
@.claude/rules/build.md
@.claude/rules/database.md
@.claude/rules/api-boundaries.md
@.claude/rules/testing.md
@.claude/rules/frontend.md
@.claude/rules/pm.md
@.claude/rules/qa.md
@.claude/rules/devops.md

---

## Code Style

- **Java**: follow existing patterns in the file being edited — don't introduce frameworks not already in use.
- **Angular**: use existing service/component structure; do not add state management libraries.
- **Shell scripts**: 2-space indentation, `set -euo pipefail`, quote all variables.
- **SQL**: MySQL 8 syntax; use `IF NOT EXISTS` guards in migrations.

---

## What NOT to Do

- Do not add comments or docstrings to code you didn't touch.
- Do not refactor code surrounding a bug fix — fix only what was asked.
- Do not create new files unless strictly necessary.
- Do not run `git push` without explicit confirmation.
- Do not run destructive commands (`rm -rf`, `docker system prune`, `DROP TABLE`) without confirmation.

---

## Verification

When fixing a bug, write a failing test first — then fix — then confirm the test passes.
When adding an API endpoint, check with `curl http://localhost:{port}/actuator/health` that the service is running, then test the endpoint.

---

## Deployment

```bash
# Full deploy to VPS (rsync + build + start — ~20-30 min first time)
bash DEPLOY_TO_VPS.sh

# Watch logs after deploy
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f"
```

- Images build **on the VPS** from source (not a registry). `docker-compose.build-override.yml` overrides image refs.
- Builds run **sequentially** — VPS has 4 GB swap + Maven heap capped at 1 GB to prevent OOM.
- Nginx starts **after** certbot — SSL certs are auto-provisioned on first deploy.

---

## Environment & Secrets

- `.env` lives at `infra/.env` — **never commit real secrets**.
- `MAPS_API_KEY` must be replaced with a real Google Maps key before production.
- Firebase credentials (`firebase-service-account.json`) must be uploaded to `/opt/sv-tms/secrets/` on VPS manually.

---

## Common Tasks

| Task | Command / File |
|---|---|
| Add DB migration | `/new-migration <description>` or create `tms-core-api/.../db/migration/V{date}__{name}.sql` |
| Add API endpoint | Edit `*Controller.java` in the correct service module |
| Check API boundaries | `/check-boundaries` |
| Check VPS health | `/deploy-status` |
| Change nginx routing | `infra/nginx/site.conf` |
| Change env var | `infra/.env` → re-run `DEPLOY_TO_VPS.sh` |
| Rebuild one service on VPS | `ssh ... "docker compose ... build {svc} && docker compose ... up -d {svc}"` |

---

## Team Slash Commands by Role

### PM
| Command | Purpose |
|---|---|
| `/new-feature <description>` | Draft feature spec with API contract, DB impact, acceptance criteria |
| `/release-notes <version or date>` | Generate release notes from git commits |

### UI / UX
| Command | Purpose |
|---|---|
| `/new-component <description>` | Scaffold Angular feature component with Material + Tailwind |

### Engineer
| Command | Purpose |
|---|---|
| `/new-migration <description>` | Scaffold Flyway migration file with correct naming |
| `/check-boundaries` | Audit all clients for API boundary violations |

### QA
| Command | Purpose |
|---|---|
| `/write-test <feature or file>` | Generate unit/integration/widget tests with coverage |

### DevOps
| Command | Purpose |
|---|---|
| `/deploy-status` | Check health of all containers on production VPS |
| `/rollback <service>` | Roll back a service to its previous image on VPS |
