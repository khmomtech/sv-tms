#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SV-TMS DevOps Agent — VPS Installer
# Run from your LOCAL machine (not on the VPS):
#   bash infra/agent/install_agent.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

VPS="root@207.180.245.156"
KEY="infra/deploy_key"
REMOTE_ROOT="/opt/sv-tms/repo"
AGENT_SRC="infra/agent"

ssh_run() {
  ssh -i "$KEY" "$VPS" "$@"
}

echo "▶ Copying agent files to VPS ..."
scp -i "$KEY" \
  "${AGENT_SRC}/svtms_agent.py" \
  "${AGENT_SRC}/svtms-agent.service" \
  "${VPS}:/tmp/"

echo "▶ Installing on VPS ..."
ssh_run bash -s <<'REMOTE'
set -euo pipefail

AGENT_DIR=/opt/sv-tms/repo/infra/agent
SYSLOG_DIR=/var/log/svtms-agent
STATE_DIR=/var/lib/svtms-agent

mkdir -p "$AGENT_DIR" "$SYSLOG_DIR" "$STATE_DIR"

# Copy files into place
cp /tmp/svtms_agent.py  "$AGENT_DIR/svtms_agent.py"
cp /tmp/svtms-agent.service /etc/systemd/system/svtms-agent.service
chmod 700 "$AGENT_DIR/svtms_agent.py"

# Verify Python 3 is available
python3 --version

# Enable and (re)start the service
systemctl daemon-reload
systemctl enable  svtms-agent.service
systemctl restart svtms-agent.service
sleep 3
systemctl status svtms-agent.service --no-pager

echo ""
echo "✅  SV-TMS Agent installed and running."
echo "    Logs  : journalctl -u svtms-agent -f"
echo "    Report: python3 $AGENT_DIR/svtms_agent.py --report"
REMOTE

echo ""
echo "Done.  To configure Telegram or webhook alerts, create an override:"
echo "  ssh -i $KEY $VPS"
echo "  mkdir -p /etc/systemd/system/svtms-agent.service.d/"
echo "  cat > /etc/systemd/system/svtms-agent.service.d/override.conf <<EOF"
echo "  [Service]"
echo "  Environment=\"AGENT_TELEGRAM_TOKEN=<your-bot-token>\""
echo "  Environment=\"AGENT_TELEGRAM_CHAT_ID=<your-chat-id>\""
echo "  EOF"
echo "  systemctl daemon-reload && systemctl restart svtms-agent"
