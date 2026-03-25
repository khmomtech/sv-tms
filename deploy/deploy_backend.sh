#!/usr/bin/env bash
set -euo pipefail

# Builds backend jar and deploys to VPS using SSH + systemd service template.
# Usage: ./deploy_backend.sh --vps user@host --ssh-key /path --port 22 --jar-path ./tms-backend/target/app.jar --service-name tms-backend

SSH_PORT=22
SERVICE_NAME=tms-backend
JAR_PATH=""

print_usage(){
  echo "Usage: $0 --vps user@host --ssh-key /path --jar-path /path/to/jar [--port PORT] [--service-name NAME] [--remote-dir /opt/$SERVICE_NAME]"
  exit 1
}

if [ $# -eq 0 ]; then
  print_usage
fi

REMOTE_DIR="/opt/$SERVICE_NAME"

while [[ $# -gt 0 ]]; do
  case $1 in
    --vps) VPS=$2; shift 2;;
    --ssh-key) SSH_KEY=$2; shift 2;;
    --jar-path) JAR_PATH=$2; shift 2;;
    --port) SSH_PORT=$2; shift 2;;
    --service-name) SERVICE_NAME=$2; shift 2;;
    --remote-dir) REMOTE_DIR=$2; shift 2;;
    *) echo "Unknown arg: $1"; print_usage;;
  esac
done

if [ -z "${VPS:-}" ] || [ -z "${SSH_KEY:-}" ] || [ -z "$JAR_PATH" ]; then
  print_usage
fi

if [ ! -f "$JAR_PATH" ]; then
  echo "Jar not found at $JAR_PATH. Building with Maven..."
  pushd tms-backend >/dev/null
  ./mvnw -DskipTests package
  popd >/dev/null
  # try default target
  JAR_CANDIDATE=$(ls tms-backend/target/*.jar 2>/dev/null | head -n1 || true)
  if [ -z "$JAR_CANDIDATE" ]; then
    echo "No jar produced. Check build output."; exit 2
  fi
  JAR_PATH="$JAR_CANDIDATE"
fi

REMOTE_JAR_PATH="$REMOTE_DIR/$(basename $JAR_PATH)"

echo "Creating remote directory $REMOTE_DIR on $VPS..."
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS" "sudo mkdir -p $REMOTE_DIR && sudo chown $USER:$USER $REMOTE_DIR"

echo "Transferring jar to $VPS:$REMOTE_JAR_PATH ..."
scp -P "$SSH_PORT" -i "$SSH_KEY" "$JAR_PATH" "$VPS":"$REMOTE_JAR_PATH"

echo "Uploading systemd service template and enabling service..."
# send service template from repo (expects file deploy/tms-backend.service.template)
SERVICE_TEMPLATE_PATH="deploy/tms-backend.service.template"
if [ ! -f "$SERVICE_TEMPLATE_PATH" ]; then
  echo "Service template not found at $SERVICE_TEMPLATE_PATH"; exit 3
fi

ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS" "sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null" < "$SERVICE_TEMPLATE_PATH"

echo "Reloading systemd and starting service..."
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS" "sudo systemctl daemon-reload && sudo systemctl enable --now $SERVICE_NAME.service"

echo "Deployment complete. Check status with: ssh -i $SSH_KEY -p $SSH_PORT $VPS 'sudo systemctl status $SERVICE_NAME'"
