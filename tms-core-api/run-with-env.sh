#!/bin/bash

set -euo pipefail

# Optional: load local secrets from .env (do not commit).
if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

if [ -x "./scripts/local-preflight.sh" ]; then
  ./scripts/local-preflight.sh
fi

./mvnw spring-boot:run -Dspring-boot.run.main-class=com.svtrucking.logistics.Application
