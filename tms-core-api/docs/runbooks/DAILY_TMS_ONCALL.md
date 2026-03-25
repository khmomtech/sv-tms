# SV Co. Ltd — On-Call Runbook (TMS)

Purpose
-------
This runbook is tailored for the on-call engineer. It lists the immediate checks, quick fixes, escalation steps, and commands to triage and mitigate incidents quickly.

Incident Triage (first 10 minutes)
----------------------------------
1. Acknowledge the alert in the pager/Slack and set status to "Investigating".
2. Identify the scope: single endpoint, single service, or system-wide.
3. Check health endpoints quickly:
   - `curl -sS http://localhost:8080/api/health | jq` → expect `status: "UP"`.
   - `curl -sS http://localhost:8080/api/health/detailed | jq` → check `uploads` and disk space.
4. Check container status:
   - `docker compose -f docker-compose.dev.yml ps`
5. Inspect recent logs for the service in question:
   - `docker compose -f docker-compose.dev.yml logs --tail 200 --no-color driver-app | sed -n '1,200p'`
6. If database errors appear, check MySQL container and recent migrations:
   - `docker compose -f docker-compose.dev.yml logs mysql`
   - `docker exec -it <mysql_container> mysql -u root -p -e 'SHOW PROCESSLIST; SHOW ENGINE INNODB STATUS\G'`

Quick Mitigations (safe, reversible)
------------------------------------
- Restart the failing service container (non-destructive):
  - `docker compose -f docker-compose.dev.yml restart driver-app`
- Flush cache or restart Redis if memory pressure/errors are observed:
  - `docker compose -f docker-compose.dev.yml restart redis`
- Free disk space on uploads if disk-full causes errors: move old files to backup and remove oldest files.

When to Paginate/Escalate
-------------------------
- Escalate to Backend Lead if:
  - The restart does not restore service within 5-10 minutes.
  - There are database corruption or schema migration failures.
  - Sensitive data leak or security breach suspected.
- Escalate to Level 3 (CTO/Senior) if:
  - Multiple critical services are down and cannot be recovered by restarts.
  - Rollback of a recent deploy is required but risky.

Communication
-------------
- Post brief incident summary in the incident channel (Slack): time, impact, steps taken, owner.
- Update the incident ticket with timestamps and commands run.
- Keep updates every 10 minutes until resolved.

Post-mortem
-----------
- After resolution, open an incident post-mortem summarizing root cause, actions, timeline, and follow-ups.
- Add remediation tasks to the backlog and update on-call runbook if needed.

Useful Commands
---------------
- Health: `curl -sS http://localhost:8080/api/health | jq`
- Detailed health: `curl -sS http://localhost:8080/api/health/detailed | jq`
- Tail backend logs: `docker compose -f docker-compose.dev.yml logs -f driver-app`
- Run tests (local): `./mvnw test`
- Build: `./mvnw clean package`

Contacts
--------
- Backend Lead: backend@example.com
- DevOps: ops@example.com
- Mobile Lead: mobile@example.com

Notes
-----
Keep this document minimal and actionable — it's intended to be used during high-pressure incidents.
