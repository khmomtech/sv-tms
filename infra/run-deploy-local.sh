#!/usr/bin/env bash
set -euo pipefail

# Wrapper to prepare .env, optionally build artifacts locally, and run infra/deploy.sh
# Usage:
#   ./infra/run-deploy-local.sh --server root@207.180.245.156 --domain svtms.svtrucking.biz --email you@yourdomain.tld [--build-backend] [--build-frontend]

usage(){
  cat <<EOF
Usage: $0 --server user@host --domain DOMAIN --email EMAIL [--build-backend] [--build-frontend]

This script:
 - ensures infra/.env exists (copies from .env.example if missing)
 - optionally builds backend/frontend locally
 - makes infra/deploy.sh executable and runs it (rsync + remote setup)

EOF
  exit 1
}

SERVER=""
DOMAIN=""
EMAIL=""
BUILD_BACKEND=0
BUILD_FRONTEND=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) SERVER="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --build-backend) BUILD_BACKEND=1; shift;;
    --build-frontend) BUILD_FRONTEND=1; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [[ -z "$SERVER" || -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "Missing required args."; usage
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# Ensure infra/.env
if [[ ! -f infra/.env ]]; then
  if [[ -f infra/.env.example ]]; then
    echo "Copying infra/.env.example → infra/.env (please edit the file to set strong passwords)"
    cp infra/.env.example infra/.env
    echo "Opened infra/.env in your editor. Save and close to continue."
    ${EDITOR:-nano} infra/.env
  else
    echo "infra/.env.example not found. Create infra/.env manually and re-run.";
    exit 1
  fi
fi

# Optionally build backend
if [[ $BUILD_BACKEND -eq 1 ]]; then
  if [[ -d tms-backend ]]; then
    echo "Building backend (maven)..."
    pushd tms-backend >/dev/null
    if [[ -x mvnw ]]; then
      ./mvnw clean package -DskipTests
    else
      mvn clean package -DskipTests
    fi
    popd >/dev/null
  else
    echo "tms-backend directory not found; skipping backend build"
  fi
fi

# Optionally build frontend
if [[ $BUILD_FRONTEND -eq 1 ]]; then
  if [[ -d tms-frontend ]]; then
    echo "Building frontend (npm)..."
    pushd tms-frontend >/dev/null
    if [[ -f package.json ]]; then
      npm ci
      npm run build -- --output-path=dist || npm run build
    fi
    popd >/dev/null
  else
    echo "tms-frontend directory not found; skipping frontend build"
  fi
fi

# Ensure deploy script is executable
chmod +x infra/deploy.sh

# Run deploy.sh
echo "Running infra/deploy.sh against $SERVER with domain $DOMAIN"
./infra/deploy.sh --repo . --server "$SERVER" --domain "$DOMAIN" --email "$EMAIL"

echo "Deploy script finished. Check server status with: ssh $SERVER 'cd /opt/sv-tms && docker compose ps'"
