#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy_stack.sh
#  - Ensures infra/.env exists, brings up the production split stack, attempts cert issuance via certbot (webroot)

cd /opt/sv-tms
COMPOSE_FILE=infra/docker-compose.prod.yml
ENV_FILE=infra/.env
PREFER_PREBUILT_IMAGES=${PREFER_PREBUILT_IMAGES:-true}

/opt/sv-tms/infra/scripts/preflight_prod.sh

if [[ -f "$ENV_FILE" ]]; then
  echo "Using /opt/sv-tms/$ENV_FILE"
  set -a
  . "$ENV_FILE"
  set +a
else
  echo "Warning: infra/.env not found in /opt/sv-tms. Please create it from infra/.env.example" >&2
fi

# Pull/build and start stack
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull || true
if [[ "$PREFER_PREBUILT_IMAGES" == "true" ]]; then
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --remove-orphans
else
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build --remove-orphans
fi

# If DOMAIN & EMAIL set, attempt cert issuance via certbot (webroot)
if [[ -n "${DOMAIN:-}" && -n "${EMAIL:-}" ]]; then
  echo "Attempting certificate issuance for ${DOMAIN}"
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" run --rm certbot certonly --webroot -w /var/www/certbot -d "${DOMAIN}" -m "${EMAIL}" --agree-tos --no-eff-email || true
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" restart nginx || true
else
  echo "DOMAIN or EMAIL not set in infra/.env; skipping cert issuance"
fi

/opt/sv-tms/infra/scripts/post_deploy_smoke.sh

echo "Deployment finished. Run 'docker compose --env-file $ENV_FILE -f $COMPOSE_FILE ps' and check logs if needed."
