# SV Co. Ltd — NOC Runbook (TMS)

Purpose
-------
This runbook is for Network/Operations Center staff who monitor system health and perform routine checks. It emphasizes monitoring dashboards, automated alerts, and quick remediation steps.

Daily Monitoring Tasks
----------------------
- Check alert dashboard (Prometheus/Grafana) for any active alerts.
- Verify recent deployment windows and any scheduled maintenance.
- Confirm disk usage for uploads and DB nodes; if >80% alert storage owner.
- Confirm backups completed successfully.

Standard Operating Procedures
----------------------------
1. Check system status:
   - Health endpoint: `curl -sS http://localhost:8080/api/health | jq`
   - Detailed: `curl -sS http://localhost:8080/api/health/detailed | jq`
2. If an alert is triggered (error rate, DB down, disk full):
   - Acknowledge alert in PagerDuty/ops tool.
   - Open an incident ticket with the alert summary and time.
3. If the alert is storage-related (uploads):
   - Run `du -sh uploads/` and check the largest consumers: `du -ah uploads | sort -rh | head -n 30`.
   - Run backups if required and coordinate with dev team for cleanup.
4. If the alert is increased 5xx error rate:
   - Check app logs: `docker compose -f docker-compose.dev.yml logs --tail 300 driver-app`
   - Check recent deployment tags/commits and roll back if necessary.

Escalation Matrix
-----------------
- NOC Operator → On-call Backend → Backend Lead → Platform/CTO.
- Use the incident template and include logs and health snapshots.

Maintenance Windows
-------------------
- All planned DB or storage maintenance must be scheduled in advance and announced to stakeholders.
- Use `docker compose -f docker-compose.dev.yml down` and `up --build -d` for full restarts during maintenance.

Routine Commands
----------------
- Check containers: `docker compose -f docker-compose.dev.yml ps`
- Tail logs: `docker compose -f docker-compose.dev.yml logs -f driver-app`
- Backup commands (as documented in repo): `./backup_docker_mysql.sh` and `./backup_docker_uploads.sh`

Contacts
--------
- NOC Lead: noc@example.com
- On-call: oncall@example.com
- Escalation: backend@example.com

Notes
-----
Keep dashboards updated and annotate any maintenance windows in Grafana.
