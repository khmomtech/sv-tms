#!/usr/bin/env bash

set -euo pipefail

check_listening() {
  local host="$1"
  local port="$2"
  if nc -z "$host" "$port" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

echo "[preflight] Checking local dependencies..."

if check_listening "127.0.0.1" "3307"; then
  echo "[ok] MySQL is reachable on 127.0.0.1:3307"
else
  echo "[error] MySQL is not reachable on 127.0.0.1:3307"
  echo "        Start MySQL first. Backend local profile expects port 3307."
  exit 1
fi

if check_listening "127.0.0.1" "6379"; then
  echo "[ok] Redis is reachable on 127.0.0.1:6379"
else
  echo "[warn] Redis is not reachable on 127.0.0.1:6379 (continuing)"
fi

if check_listening "127.0.0.1" "8080"; then
  echo "[warn] Port 8080 already has a listener."
  echo "       Ensure this is your intended backend instance."
else
  echo "[ok] Port 8080 is free for backend startup"
fi

echo "[preflight] Completed."
