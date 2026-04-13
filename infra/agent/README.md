# SV-TMS DevOps AI Agent

An autonomous monitoring and self-healing agent for the SV-TMS production stack.

## What it does

Every 60 seconds (configurable) the agent:

1. **Checks all containers** — `docker inspect` state + healthcheck status for every service
2. **Checks Spring Boot actuators** — `curl /actuator/health` inside each API container
3. **Auto-restarts failed services** — up to 3 attempts with a 2-minute cooldown between them
4. **Escalates if restart fails** — sends a critical alert asking for manual intervention
5. **Monitors disk** — warns at 85% used, critical at 92%
6. **Monitors swap** — warns at 80% (high swap slows Maven builds)
7. **Sends alerts** — Telegram and/or a generic JSON webhook

## Services monitored

| Service | Container | Auto-restart |
|---|---|---|
| core-api | svtms-core-api | ✅ |
| auth-api | svtms-auth-api | ✅ |
| telematics-api | svtms-telematics-api | ✅ |
| driver-app-api | svtms-driver-app-api | ✅ |
| safety-api | svtms-safety-api | ✅ |
| message-api | svtms-message-api | ✅ |
| api-gateway | svtms-api-gateway | ✅ |
| mysql / postgres / redis / mongo | — | ❌ (alert only) |
| kafka-1 / kafka-2 / kafka-3 | — | ❌ (alert only) |

Infrastructure containers are not auto-restarted — they have `restart: unless-stopped` in compose and restarting them unsafely can cause data loss.

## Quick install

```bash
# From your local machine (repo root):
bash infra/agent/install_agent.sh
```

That rsync's the agent files, installs the systemd unit, and starts the service.

## Manual operation on VPS

```bash
# Live logs
journalctl -u svtms-agent -f

# One-off status report
python3 /opt/sv-tms/repo/infra/agent/svtms_agent.py --report

# Single check cycle (good for cron)
python3 /opt/sv-tms/repo/infra/agent/svtms_agent.py --once

# Stop / start / restart the agent itself
systemctl stop    svtms-agent
systemctl start   svtms-agent
systemctl restart svtms-agent
```

## Configuration

All settings are environment variables. Override them without editing the script:

```bash
mkdir -p /etc/systemd/system/svtms-agent.service.d/
cat > /etc/systemd/system/svtms-agent.service.d/override.conf <<EOF
[Service]
# Notification targets
Environment="AGENT_TELEGRAM_TOKEN=bot<your-token>"
Environment="AGENT_TELEGRAM_CHAT_ID=-100<your-chat-id>"
Environment="AGENT_WEBHOOK_URL=https://hooks.example.com/svtms"

# Tuning
Environment="POLL_INTERVAL=30"
Environment="MAX_RESTARTS=5"
Environment="DISK_WARN_PCT=80"
EOF

systemctl daemon-reload && systemctl restart svtms-agent
```

| Variable | Default | Description |
|---|---|---|
| `POLL_INTERVAL` | 60 | Seconds between full checks |
| `RESTART_COOLDOWN` | 120 | Seconds before re-restarting the same service |
| `MAX_RESTARTS` | 3 | Auto-restart attempts before escalating |
| `DISK_WARN_PCT` | 85 | Disk % used → warning alert |
| `DISK_CRIT_PCT` | 92 | Disk % used → critical alert |
| `SWAP_WARN_PCT` | 80 | Swap % used → warning alert |
| `AGENT_WEBHOOK_URL` | — | POST JSON alerts here |
| `AGENT_TELEGRAM_TOKEN` | — | Telegram bot token |
| `AGENT_TELEGRAM_CHAT_ID` | — | Telegram chat/group ID |

## Webhook payload format

```json
{
  "severity": "critical",
  "subject": "core-api is DOWN",
  "body": "Container: exited | Health: unhealthy | Actuator: DOWN",
  "timestamp": "2026-04-04 08:12 UTC",
  "source": "svtms-agent"
}
```

`severity` is one of `warning`, `critical`, or `resolved`.

## File locations on VPS

| Path | Purpose |
|---|---|
| `/opt/sv-tms/repo/infra/agent/svtms_agent.py` | Agent script |
| `/etc/systemd/system/svtms-agent.service` | Systemd unit |
| `/etc/systemd/system/svtms-agent.service.d/override.conf` | Local config/secrets |
| `/var/log/svtms-agent/agent.log` | Log file |
| `/var/lib/svtms-agent/state.json` | Restart counters / alert state |
