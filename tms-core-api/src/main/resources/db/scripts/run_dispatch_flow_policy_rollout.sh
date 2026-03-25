#!/usr/bin/env bash
set -euo pipefail

# One-click rollout for dispatch flow policy
# Usage:
#   ./run_dispatch_flow_policy_rollout.sh -u <db_user> -d <db_name> [-h <db_host>] [-P <db_port>] [--snapshot] [--map-khbl]
#
# Example:
#   ./run_dispatch_flow_policy_rollout.sh -u root -d sv_tms --snapshot --map-khbl

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USER=""
DB_NAME=""
DO_SNAPSHOT="false"
DO_MAP_KHBL="false"

print_usage() {
  cat <<'EOF'
Usage:
  run_dispatch_flow_policy_rollout.sh -u <db_user> -d <db_name> [-h <db_host>] [-P <db_port>] [--snapshot] [--map-khbl]

Options:
  -u, --user        Database user (required)
  -d, --database    Database name (required)
  -h, --host        Database host (default: 127.0.0.1)
  -P, --port        Database port (default: 3306)
  --snapshot        Run preflight snapshot before rollout
  --map-khbl        Run KHBL assignment mapping after reset+seed
  --help            Show this help

Notes:
  - Password will be prompted by mysql client.
  - Ensure scripts exist in the same folder.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user)
      DB_USER="${2:-}"
      shift 2
      ;;
    -d|--database)
      DB_NAME="${2:-}"
      shift 2
      ;;
    -h|--host)
      DB_HOST="${2:-}"
      shift 2
      ;;
    -P|--port)
      DB_PORT="${2:-}"
      shift 2
      ;;
    --snapshot)
      DO_SNAPSHOT="true"
      shift
      ;;
    --map-khbl)
      DO_MAP_KHBL="true"
      shift
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      print_usage
      exit 1
      ;;
  esac
done

if [[ -z "$DB_USER" || -z "$DB_NAME" ]]; then
  echo "Error: --user and --database are required." >&2
  print_usage
  exit 1
fi

MYSQL=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p "$DB_NAME")

run_sql_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Missing script file: $file" >&2
    exit 1
  fi
  echo "\n==> Running: $(basename "$file")"
  "${MYSQL[@]}" < "$file"
}

if [[ "$DO_SNAPSHOT" == "true" ]]; then
  SNAP_FILE="$SCRIPT_DIR/dispatch_flow_policy_preflight_snapshot.sql"
  TMP_FILE="$(mktemp)"
  SNAP_SUFFIX="$(date +%Y%m%d_%H%M%S)"
  sed "s/SET @suffix = '.*';/SET @suffix = '${SNAP_SUFFIX}';/" "$SNAP_FILE" > "$TMP_FILE"
  run_sql_file "$TMP_FILE"
  rm -f "$TMP_FILE"
  echo "Snapshot suffix: $SNAP_SUFFIX"
fi

run_sql_file "$SCRIPT_DIR/dispatch_flow_policy_reset_and_seed.sql"

if [[ "$DO_MAP_KHBL" == "true" ]]; then
  run_sql_file "$SCRIPT_DIR/dispatch_flow_policy_assign_khbl_by_rules.sql"
fi

echo "\n==> Final verification"
"${MYSQL[@]}" <<'SQL'
SELECT code, name, active FROM dispatch_flow_template ORDER BY code;

SELECT t.code, COUNT(*) AS rule_count
FROM dispatch_flow_template t
LEFT JOIN dispatch_flow_transition_rule r ON r.template_id = t.id
GROUP BY t.code
ORDER BY t.code;

SELECT loading_type_code, COUNT(*) AS total_dispatches
FROM dispatches
GROUP BY loading_type_code
ORDER BY loading_type_code;
SQL

echo "\nRollout completed successfully."
