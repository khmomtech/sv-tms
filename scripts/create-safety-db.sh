#!/usr/bin/env bash
set -euo pipefail

# Creates the safety_db database and grants access.
# Useful when the MySQL container already exists (init scripts only run on first boot).
#
# Usage:
#   scripts/create-safety-db.sh
#   MYSQL_CONTAINER=svtms-mysql MYSQL_ROOT_PASSWORD=rootpass scripts/create-safety-db.sh

MYSQL_CONTAINER="${MYSQL_CONTAINER:-svtms-mysql}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpass}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found on PATH" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | rg -q "^${MYSQL_CONTAINER}\$" 2>/dev/null; then
  # fallback for environments without ripgrep
  if ! docker ps --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}\$"; then
    echo "MySQL container '${MYSQL_CONTAINER}' is not running." >&2
    echo "Set MYSQL_CONTAINER=... to match your compose container name." >&2
    exit 1
  fi
fi

docker exec -i "${MYSQL_CONTAINER}" mysql -uroot "-p${MYSQL_ROOT_PASSWORD}" <<'SQL'
CREATE DATABASE IF NOT EXISTS safety_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'driver'@'%' IDENTIFIED BY 'driverpass';
GRANT ALL PRIVILEGES ON safety_db.* TO 'driver'@'%';
FLUSH PRIVILEGES;
SQL

echo "OK: safety_db ensured and privileges granted (container: ${MYSQL_CONTAINER})"

