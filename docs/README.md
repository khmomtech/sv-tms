# SV-TMS Docs

Single starting point for all project documentation.

---

## Guides

| Doc | Who | Purpose |
|---|---|---|
| [Local Development](../LOCAL_DEVELOPMENT.md) | Engineers | Canonical local setup, ports, Docker profiles, frontend run/test flow |
| [System Architecture](guides/SA_DOCUMENT.md) | All | Service map, data flow, split model |
| [Infrastructure Guide](guides/INFRASTRUCTURE_GUIDE.md) | DevOps | VPS, Docker, networking overview |
| [Development Guide](guides/DEVELOPMENT_GUIDE.md) | Engineers | How to build and run services locally |
| [Integration Debug Guide](guides/INTEGRATION_DEVELOPMENT_DEBUG_GUIDE.md) | Engineers | Debugging cross-service issues |
| [Ongoing Maintenance Guide](guides/ONGOING_MAINTENANCE_GUIDE.md) | DevOps | Day-to-day ops and health checks |
| [Production Readiness Checklist](guides/PRODUCTION_READINESS_CHECKLIST.md) | All | Pre-release gates |
| [Driver App Admin UI Guide](guides/DRIVER_APP_ADMIN_UI_GUIDE.md) | Admin / Ops | Driver app updates, maintenance, alerts, settings |
| [Telematics API Migration Note](guides/TELEMATICS_API_MIGRATION_NOTE.md) | Engineers | Canonical telematics URLs and legacy alias sunset policy |
| [Team Cowork Guide](guides/TEAM_COWORK_GUIDE.md) | All | Claude Code by role: PM, UI/UX, Engineer, QA, DevOps |

---

## SOPs

| SOP | Who | Purpose |
|---|---|---|
| [SOP 01 — Daily Operations](guides/SOP_01_DAILY_OPERATIONS.md) | DevOps | Daily health checks |
| [SOP 02 — Release & Deployment](guides/SOP_02_RELEASE_DEPLOYMENT.md) | DevOps | Deploy a release |
| [SOP 03 — Incident Response](guides/SOP_03_INCIDENT_RESPONSE.md) | DevOps | Handle production incidents |
| [SOP 04 — Rollback & Recovery](guides/SOP_04_ROLLBACK_AND_RECOVERY.md) | DevOps | Roll back a bad deploy |
| [SOP 05 — Handover & Reporting](guides/SOP_05_HANDOVER_AND_REPORTING.md) | DevOps | Shift handover |
| [SOP — Dynamic Driver App Control](guides/SOP_DYNAMIC_DRIVER_APP_CONTROL.md) | PM / DevOps | Runtime driver app config |
| [SOP — Khmer Split Ops](guides/SOP_KHMER_SPLIT.md) | DevOps (KH) | Khmer-language operations |
| [SOP Index](guides/SOP_INDEX.md) | All | All SOPs in one place |

---

## VPS Runbook

[VPS Maintenance & Monitoring Runbook](deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md) — live monitoring, known fixes, routing triage, post-deploy validation.

---

## Frontend & Mobile

| Doc | Purpose |
|---|---|
| [Driver API Facade Map](frontend/DRIVER_API_FACADE_MAP.md) | Canonical endpoint map for driver app features |
| [Dynamic Driver App Admin Keys](frontend/DYNAMIC_DRIVER_APP_ADMIN_KEYS.md) | Admin config keys for screens, features, navigation |
| [Cleanup Priorities](frontend/CLEANUP_FREEZE_DEAD_OVERLAP_PRIORITIES.md) | Dead routes, legacy deps, P0/P1/P2 cleanup |
| [Flow Inventory Matrix](frontend/CLEANUP_FLOW_INVENTORY_MATRIX.md) | Flow inventory with API endpoints and ownership |

---

## Safety Module

| Doc | Purpose |
|---|---|
| [Safety Module Overview](safety/README.md) | Driver daily safety check feature |
| [Safety SOP (Khmer)](safety/SOP_KHMER.md) | Khmer-language safety walkthrough |
| [Safety Assumptions](safety/ASSUMPTIONS.md) | Design decisions and constraints |

---

## G Team (Loading & Safety Ops)

| Doc | Purpose |
|---|---|
| [Safety & Loading Recap](G_TEAM/safety_loading.md) | Immediate actions and status |
| [Follow-ups](G_TEAM/followups.md) | Outstanding items by priority |
| [Pre-shift Checklist](G_TEAM/checklist.yaml) | Pre-shift loading checklist template |

---

## Other

| Doc | Purpose |
|---|---|
| [Cleanup Execution Plan](guides/CLEANUP_3_PHASE_EXECUTION.md) | 3-phase mobile API cleanup with test gates |
| [Boss Brief — Prod Release](guides/BOSS_BRIEF_PROD_RELEASE.md) | Executive summary for stakeholders |
| [Postman Collection](postman/tms-backend.postman_collection.json) | Sample API requests |

---

## Conflict Resolution

If two docs disagree, this is the priority order:

1. `CLAUDE.md` (root) — code and collaboration rules
2. `docs/guides/` — technical guides
3. `docs/deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md` — operational runbook
4. `LOCAL_DEVELOPMENT.md` (root) — local setup
