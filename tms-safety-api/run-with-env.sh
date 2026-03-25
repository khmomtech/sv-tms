#!/bin/bash

# Optional: load local secrets from .env (do not commit).
if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

./mvnw spring-boot:run
