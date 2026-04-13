#!/usr/bin/env python3
"""
SV-TMS DevOps AI Agent
=======================
Monitors all SV-TMS services on the production VPS, auto-heals failed
containers, and sends alert notifications.

Run modes:
  --once     Run a single check cycle and exit (good for cron)
  --daemon   Run continuously on the configured POLL_INTERVAL (default)
  --report   Print a one-shot status report to stdout and exit

Configuration is via environment variables (see CONFIG section below).
"""

import argparse
import json
import logging
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG  (override any of these via environment variables)
# ─────────────────────────────────────────────────────────────────────────────
STACK_ROOT       = os.getenv("STACK_ROOT",       "/opt/sv-tms/repo")
COMPOSE_FILE     = os.getenv("COMPOSE_FILE",     f"{STACK_ROOT}/infra/docker-compose.prod.yml")
OVERRIDE_FILE    = os.getenv("OVERRIDE_FILE",    f"{STACK_ROOT}/infra/docker-compose.build-override.yml")
ENV_FILE         = os.getenv("ENV_FILE",         f"{STACK_ROOT}/infra/.env")
LOG_FILE         = os.getenv("LOG_FILE",         "/var/log/svtms-agent/agent.log")
STATE_FILE       = os.getenv("STATE_FILE",       "/var/lib/svtms-agent/state.json")
POLL_INTERVAL    = int(os.getenv("POLL_INTERVAL", "60"))       # seconds between full checks
RESTART_COOLDOWN = int(os.getenv("RESTART_COOLDOWN", "120"))   # seconds before re-restarting a service
MAX_RESTARTS     = int(os.getenv("MAX_RESTARTS", "3"))         # restarts before escalating alert
DISK_WARN_PCT    = float(os.getenv("DISK_WARN_PCT", "85"))     # % used → warning
DISK_CRIT_PCT    = float(os.getenv("DISK_CRIT_PCT", "92"))     # % used → critical
SWAP_WARN_PCT    = float(os.getenv("SWAP_WARN_PCT", "80"))     # % used → warning

# Webhook / Telegram alert targets (set at least one)
WEBHOOK_URL      = os.getenv("AGENT_WEBHOOK_URL", "")          # generic JSON webhook
TELEGRAM_TOKEN   = os.getenv("AGENT_TELEGRAM_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("AGENT_TELEGRAM_CHAT_ID", "")

# ─────────────────────────────────────────────────────────────────────────────
# SERVICE DEFINITIONS — mirrors CLAUDE.md / ports.md / docker-compose.prod.yml
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class ServiceDef:
    compose_name: str          # docker compose service name
    container:    str          # docker container name
    port:         int          # actuator health port (inside container)
    critical:     bool = True  # if True, alert immediately on failure

SERVICES: list[ServiceDef] = [
    ServiceDef("core-api",        "svtms-core-api",        8080),
    ServiceDef("auth-api",        "svtms-auth-api",        8083),
    ServiceDef("telematics-api",  "svtms-telematics-api",  8082),
    ServiceDef("driver-app-api",  "svtms-driver-app-api",  8084),
    ServiceDef("safety-api",      "svtms-safety-api",      8087),
    ServiceDef("message-api",     "svtms-message-api",     8088),
    ServiceDef("api-gateway",     "svtms-api-gateway",     8086),
    # Infrastructure — compose manages restarts, agent just monitors
    ServiceDef("mysql",           "svtms-mysql",           3306, critical=True),
    ServiceDef("postgres",        "svtms-postgres",        5432, critical=True),
    ServiceDef("redis",           "svtms-redis",           6379, critical=True),
    ServiceDef("mongo",           "svtms-mongo",           27017, critical=False),
    ServiceDef("kafka-1",         "svtms-kafka-1",         9092,  critical=True),
    ServiceDef("kafka-2",         "svtms-kafka-2",         9092,  critical=False),
    ServiceDef("kafka-3",         "svtms-kafka-3",         9092,  critical=False),
]

# Services the agent is allowed to restart automatically
AUTO_RESTART_ALLOWED = {
    "core-api", "auth-api", "telematics-api",
    "driver-app-api", "safety-api", "message-api", "api-gateway",
}

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
def setup_logging() -> logging.Logger:
    Path(LOG_FILE).parent.mkdir(parents=True, exist_ok=True)
    fmt = "%(asctime)s [%(levelname)s] %(message)s"
    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]
    try:
        handlers.append(logging.FileHandler(LOG_FILE))
    except PermissionError:
        pass  # running locally without /var/log access
    logging.basicConfig(level=logging.INFO, format=fmt, handlers=handlers)
    return logging.getLogger("svtms-agent")

log = setup_logging()

# ─────────────────────────────────────────────────────────────────────────────
# STATE PERSISTENCE  (tracks restart counts / cooldowns between cycles)
# ─────────────────────────────────────────────────────────────────────────────
def load_state() -> dict:
    try:
        return json.loads(Path(STATE_FILE).read_text())
    except Exception:
        return {}

def save_state(state: dict) -> None:
    Path(STATE_FILE).parent.mkdir(parents=True, exist_ok=True)
    Path(STATE_FILE).write_text(json.dumps(state, indent=2))

# ─────────────────────────────────────────────────────────────────────────────
# DOCKER / COMPOSE HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def compose_cmd() -> list[str]:
    return [
        "docker", "compose",
        "--env-file", ENV_FILE,
        "-f", COMPOSE_FILE,
        "-f", OVERRIDE_FILE,
    ]

def run(cmd: list[str], timeout: int = 30) -> tuple[int, str, str]:
    """Run a shell command, return (returncode, stdout, stderr)."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return 1, "", "Command timed out"
    except FileNotFoundError as exc:
        return 1, "", str(exc)

def get_container_status(container: str) -> str:
    """Return docker inspect .State.Status for a container."""
    rc, out, _ = run(["docker", "inspect", "--format", "{{.State.Status}}", container])
    return out.strip() if rc == 0 else "missing"

def get_container_health(container: str) -> str:
    """Return docker inspect .State.Health.Status (or 'none' if no healthcheck)."""
    rc, out, _ = run(["docker", "inspect", "--format",
                       "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}",
                       container])
    return out.strip() if rc == 0 else "unknown"

def restart_service(svc: ServiceDef) -> bool:
    """Restart a single compose service. Returns True on success."""
    log.warning("AUTO-HEAL: restarting %s ...", svc.compose_name)
    rc, out, err = run(compose_cmd() + ["restart", svc.compose_name], timeout=120)
    if rc == 0:
        log.info("AUTO-HEAL: %s restarted successfully", svc.compose_name)
        return True
    log.error("AUTO-HEAL FAILED for %s: %s", svc.compose_name, err or out)
    return False

def get_disk_usage() -> list[dict]:
    """Return list of {mount, used_pct, avail_gb} for real filesystems."""
    rc, out, _ = run(["df", "-BG", "--output=target,pcent,avail"])
    if rc != 0:
        return []
    results = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 3:
            continue
        mount, pct_str, avail_str = parts[0], parts[1], parts[2]
        # skip overlayfs / tmpfs
        if any(x in mount for x in ("overlay", "tmpfs", "devtmpfs", "udev")):
            continue
        try:
            pct = float(pct_str.rstrip("%"))
            avail_gb = float(avail_str.rstrip("G"))
            results.append({"mount": mount, "used_pct": pct, "avail_gb": avail_gb})
        except ValueError:
            continue
    return results

def get_swap_usage() -> dict:
    """Return {used_pct, used_mb, total_mb}."""
    rc, out, _ = run(["free", "-m"])
    if rc != 0:
        return {}
    for line in out.splitlines():
        if line.startswith("Swap:"):
            parts = line.split()
            if len(parts) >= 3:
                total, used = int(parts[1]), int(parts[2])
                pct = (used / total * 100) if total else 0
                return {"used_pct": pct, "used_mb": used, "total_mb": total}
    return {}

# ─────────────────────────────────────────────────────────────────────────────
# ACTUATOR HEALTH CHECK  (Spring Boot /actuator/health)
# ─────────────────────────────────────────────────────────────────────────────
def check_actuator(svc: ServiceDef) -> Optional[str]:
    """
    Runs `docker exec` to curl the actuator inside the container.
    Returns 'UP', 'DOWN', or 'UNKNOWN'.
    Only attempted for Spring Boot services (ports 8080-8088).
    """
    if not (8080 <= svc.port <= 8099):
        return None  # not a Spring Boot service
    cmd = [
        "docker", "exec", svc.container,
        "curl", "-fsS", "--max-time", "5",
        f"http://localhost:{svc.port}/actuator/health"
    ]
    rc, out, _ = run(cmd, timeout=15)
    if rc != 0:
        return "DOWN"
    try:
        data = json.loads(out)
        return data.get("status", "UNKNOWN")
    except json.JSONDecodeError:
        return "UP" if rc == 0 else "DOWN"

# ─────────────────────────────────────────────────────────────────────────────
# ALERTING
# ─────────────────────────────────────────────────────────────────────────────
def _http_post(url: str, payload: dict) -> bool:
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        url, data=body,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10):
            return True
    except Exception as exc:
        log.error("Alert POST failed: %s", exc)
        return False

def send_alert(subject: str, body: str, severity: str = "warning") -> None:
    """Send an alert to all configured notification channels."""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    full_msg = f"[SV-TMS Agent] [{severity.upper()}] {subject}\n{ts}\n\n{body}"
    log.warning("ALERT [%s]: %s — %s", severity.upper(), subject, body)

    if WEBHOOK_URL:
        _http_post(WEBHOOK_URL, {
            "severity": severity,
            "subject": subject,
            "body": body,
            "timestamp": ts,
            "source": "svtms-agent",
        })

    if TELEGRAM_TOKEN and TELEGRAM_CHAT_ID:
        emoji = "🔴" if severity == "critical" else "🟡"
        text = f"{emoji} *SV-TMS Agent*\n*{subject}*\n`{ts}`\n\n{body}"
        _http_post(
            f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
            {"chat_id": TELEGRAM_CHAT_ID, "text": text, "parse_mode": "Markdown"}
        )

def send_resolved(subject: str) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    log.info("RESOLVED: %s", subject)
    if WEBHOOK_URL:
        _http_post(WEBHOOK_URL, {
            "severity": "resolved",
            "subject": subject,
            "timestamp": ts,
            "source": "svtms-agent",
        })
    if TELEGRAM_TOKEN and TELEGRAM_CHAT_ID:
        text = f"✅ *SV-TMS Agent — RESOLVED*\n*{subject}*\n`{ts}`"
        _http_post(
            f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
            {"chat_id": TELEGRAM_CHAT_ID, "text": text, "parse_mode": "Markdown"}
        )

# ─────────────────────────────────────────────────────────────────────────────
# MAIN CHECK LOGIC
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class CheckResult:
    service:         str
    container_state: str          # running / exited / missing / …
    health:          str          # healthy / unhealthy / none / unknown / missing
    actuator:        Optional[str]  # UP / DOWN / UNKNOWN / None
    restarted:       bool = False
    restart_count:   int  = 0
    escalated:       bool = False

def check_services(state: dict) -> list[CheckResult]:
    now = time.time()
    results: list[CheckResult] = []

    for svc in SERVICES:
        svc_state = state.setdefault(svc.compose_name, {
            "restart_count": 0,
            "last_restart": 0.0,
            "alerted": False,
            "escalated": False,
        })

        container_state = get_container_status(svc.container)
        health          = get_container_health(svc.container)
        actuator        = check_actuator(svc)

        is_running  = container_state == "running"
        is_healthy  = health in ("healthy", "none")   # "none" = no healthcheck defined
        api_ok      = actuator in (None, "UP")

        ok = is_running and is_healthy and api_ok

        if ok:
            # Service is fine — clear any previous alert state
            if svc_state["alerted"]:
                send_resolved(f"{svc.compose_name} is back UP")
                svc_state.update({"alerted": False, "escalated": False, "restart_count": 0})
            results.append(CheckResult(
                service=svc.compose_name,
                container_state=container_state,
                health=health,
                actuator=actuator,
                restart_count=svc_state["restart_count"],
            ))
            continue

        # ── Service is NOT ok ──────────────────────────────────────────────
        rc_count = svc_state["restart_count"]
        last_restart = svc_state["last_restart"]
        restarted  = False
        escalated  = False

        # Attempt auto-restart if eligible
        if (svc.compose_name in AUTO_RESTART_ALLOWED
                and rc_count < MAX_RESTARTS
                and (now - last_restart) > RESTART_COOLDOWN):

            restarted = restart_service(svc)
            if restarted:
                svc_state["restart_count"] = rc_count + 1
                svc_state["last_restart"]  = now
                send_alert(
                    f"{svc.compose_name} restarted (attempt {rc_count + 1}/{MAX_RESTARTS})",
                    f"Container state: {container_state} | Health: {health} | Actuator: {actuator}",
                    severity="warning" if not svc.critical else "critical",
                )
                svc_state["alerted"] = True

        elif rc_count >= MAX_RESTARTS and not svc_state["escalated"]:
            # Too many restarts — escalate
            escalated = True
            svc_state["escalated"] = True
            send_alert(
                f"ESCALATION: {svc.compose_name} failed {rc_count} restart attempts",
                (f"Container: {container_state} | Health: {health} | Actuator: {actuator}\n"
                 f"Manual intervention required on VPS 207.180.245.156"),
                severity="critical",
            )

        elif not svc_state["alerted"]:
            # First-time alert (non-auto-restart service or still in cooldown)
            svc_state["alerted"] = True
            send_alert(
                f"{svc.compose_name} is DOWN",
                f"Container: {container_state} | Health: {health} | Actuator: {actuator}",
                severity="critical" if svc.critical else "warning",
            )

        results.append(CheckResult(
            service=svc.compose_name,
            container_state=container_state,
            health=health,
            actuator=actuator,
            restarted=restarted,
            restart_count=svc_state["restart_count"],
            escalated=escalated,
        ))

    return results

def check_infrastructure(state: dict) -> list[str]:
    """Check disk and swap; return list of warning/critical messages."""
    warnings: list[str] = []

    for disk in get_disk_usage():
        pct   = disk["used_pct"]
        mount = disk["mount"]
        key   = f"disk_{mount.replace('/', '_')}"
        sev   = None
        if pct >= DISK_CRIT_PCT:
            sev = "critical"
            msg = f"Disk CRITICAL on {mount}: {pct:.1f}% used, {disk['avail_gb']:.1f} GB free"
        elif pct >= DISK_WARN_PCT:
            sev = "warning"
            msg = f"Disk WARNING on {mount}: {pct:.1f}% used, {disk['avail_gb']:.1f} GB free"
        else:
            if state.get(key, {}).get("alerted"):
                send_resolved(f"Disk pressure resolved on {mount}")
            state[key] = {"alerted": False}
            continue

        if not state.get(key, {}).get("alerted"):
            send_alert(msg, f"VPS: 207.180.245.156 — mountpoint {mount}", severity=sev)
            state[key] = {"alerted": True}
        warnings.append(msg)

    swap = get_swap_usage()
    if swap:
        pct = swap["used_pct"]
        if pct >= SWAP_WARN_PCT:
            msg = f"Swap WARNING: {pct:.1f}% used ({swap['used_mb']}MB / {swap['total_mb']}MB)"
            if not state.get("swap_alerted"):
                send_alert(msg, "High swap may cause OOM during Maven builds.", severity="warning")
                state["swap_alerted"] = True
            warnings.append(msg)
        else:
            if state.get("swap_alerted"):
                send_resolved("Swap pressure resolved")
            state["swap_alerted"] = False

    return warnings

# ─────────────────────────────────────────────────────────────────────────────
# REPORT FORMATTER
# ─────────────────────────────────────────────────────────────────────────────
def print_report(results: list[CheckResult], warnings: list[str]) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    print(f"\n{'='*60}")
    print(f"  SV-TMS DevOps Agent — Status Report  ({ts})")
    print(f"{'='*60}")

    # Service table
    header = f"{'SERVICE':<22} {'CONTAINER':<10} {'HEALTH':<12} {'ACTUATOR':<10} {'RESTARTS'}"
    print(f"\n{header}")
    print("-" * len(header))

    for r in results:
        actuator_str = r.actuator if r.actuator is not None else "n/a"
        container_icon = "✅" if r.container_state == "running" else "❌"
        health_icon    = "✅" if r.health in ("healthy", "none") else "❌"
        api_icon       = "✅" if actuator_str in ("UP", "n/a") else "❌"
        print(
            f"{r.service:<22} "
            f"{container_icon} {r.container_state:<8} "
            f"{health_icon} {r.health:<10} "
            f"{api_icon} {actuator_str:<8} "
            f"{r.restart_count}"
        )

    # Infrastructure warnings
    if warnings:
        print(f"\n⚠️  Infrastructure Warnings:")
        for w in warnings:
            print(f"   • {w}")
    else:
        print(f"\n✅ Disk and swap look healthy.")

    print(f"\n{'='*60}\n")

# ─────────────────────────────────────────────────────────────────────────────
# ENTRYPOINTS
# ─────────────────────────────────────────────────────────────────────────────
def run_once() -> None:
    state = load_state()
    results  = check_services(state)
    warnings = check_infrastructure(state)
    save_state(state)
    log.info(
        "Check complete: %d services, %d warnings",
        len(results), len(warnings)
    )

def run_daemon() -> None:
    log.info("SV-TMS Agent starting — poll every %ds", POLL_INTERVAL)
    while True:
        try:
            run_once()
        except Exception as exc:
            log.exception("Unexpected error in check cycle: %s", exc)
        time.sleep(POLL_INTERVAL)

def run_report() -> None:
    state    = load_state()
    results  = check_services(state)
    warnings = check_infrastructure(state)
    save_state(state)
    print_report(results, warnings)

# ─────────────────────────────────────────────────────────────────────────────
def main() -> None:
    parser = argparse.ArgumentParser(description="SV-TMS DevOps AI Agent")
    group  = parser.add_mutually_exclusive_group()
    group.add_argument("--once",   action="store_true", help="Single check cycle then exit")
    group.add_argument("--daemon", action="store_true", help="Run continuously (default)")
    group.add_argument("--report", action="store_true", help="Print status report and exit")
    args = parser.parse_args()

    if args.once:
        run_once()
    elif args.report:
        run_report()
    else:
        run_daemon()

if __name__ == "__main__":
    main()
