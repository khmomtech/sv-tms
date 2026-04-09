# SV Co. Ltd — Support Runbook (TMS)

Purpose
-------
This runbook is for Tier 1/2 support staff handling customer tickets and troubleshooting user-facing issues.

First Response Checklist
------------------------
- Gather customer details: user ID, timestamps, device, app version, steps to reproduce, and screenshots/logs.
- Try to reproduce the issue locally or on staging.
- Check service health and recent errors:
  - `curl -sS http://localhost:8080/api/health | jq`
  - `docker compose -f docker-compose.dev.yml logs --tail 200 driver-app`

Common Support Scenarios
------------------------
1. Document upload failing for driver:
   - Check `uploads` path and file permissions.
   - Verify request payload and file size limits.
   - If failure reproducible, collect server logs and escalate to Backend.
2. Driver not receiving assignments or notifications:
   - Check notification service status and STOMP/WebSocket broker health.
   - Check device registration and push token records.
3. Login issues:
   - Ask user to clear cache and reattempt.
   - If server-side, check `auth` logs for failed attempts and token generation errors.

Workarounds (Safe)
------------------
- Advise user to retry the operation after a short wait if the backend is under load.
- For failed uploads, suggest compressing images or reducing file size.

Escalation
----------
- If issue cannot be resolved in 30 minutes or impacts many users, escalate to Backend and On-call with ticket details and reproduction steps.

Support Commands
----------------
- Reproduce locally: `./mvnw spring-boot:run` (in `driver-app`) and use Postman or `curl` to replay requests.
- Tail logs for a user: `docker compose -f docker-compose.dev.yml logs --since 1h --tail 500 driver-app | grep '<user-id>' -n`.

Customer Communication
----------------------
- Acknowledge issue within SLA and provide ETA for follow-up.
- Give a succinct summary of next steps and whether a workaround is possible.

Contacts
--------
- Support Lead: support@example.com
- Backend Team: backend@example.com
- On-call: oncall@example.com

Notes
-----
- Do not share internal logs or secrets with customers.
- Keep ticket notes factual and timestamped.
