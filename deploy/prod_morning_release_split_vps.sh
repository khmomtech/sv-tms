#!/usr/bin/env bash
set -euo pipefail

# Split microservices production release orchestrator (auth + driver-app).
# Enforces go/no-go gates:
# 1) preflight build/tests
# 2) DB backup verification
# 3) service health
# 4) routing smoke
# 5) OpenAPI ownership smoke
# 6) dynamic driver-policy smoke
# 7) dispatch workflow smoke (optional but recommended for staging/pilot)
# 8) rollback readiness check
#
# Notes:
# - This script does not build deployment artifacts itself; use your existing deploy command.
# - Real mobile smoke is manual and recorded in generated report.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${ROOT_DIR}/deploy"
REPORT_DIR="${DEPLOY_DIR}/reports"

VPS=""
SSH_PORT=22
SSH_KEY=""
PASSWORD_AUTH=false

PUBLIC_URL="https://svtms.svtrucking.biz"
AUTH_LOCAL_URL="http://127.0.0.1:8083"
DRIVER_LOCAL_URL="http://127.0.0.1:8084"
AUTH_LOGIN_PATH="/api/auth/login"
SETTINGS_VALUE_PATH="/api/admin/settings/value"

NGINX_CONF_PATH="/etc/nginx/sites-available/svtms"
BACKUP_CMD="/opt/sv-tms/deploy/prod_backup_vps.sh"
ROLLBACK_CMD="/opt/sv-tms/deploy/prod_rollback_vps.sh"
DEPLOY_CMD=""

SKIP_PREFLIGHT=false
SKIP_DB_BACKUP=false
SKIP_NGINX_CONTRACT=false
SKIP_REMOTE_RESTART=false
MANUAL_SMOKE_STATUS="pending"
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
ADMIN_TOKEN=""
DRIVER_USERNAME=""
DRIVER_PASSWORD=""
DRIVER_TOKEN=""
WORKFLOW_GENERAL_DISPATCH_ID=""
WORKFLOW_KHBL_DISPATCH_ID=""
WORKFLOW_FALLBACK_DISPATCH_ID=""
WORKFLOW_FALLBACK_LINKED_TEMPLATE=""
DISPATCH_WORKFLOW_SMOKE_STATUS="skipped"

usage() {
  cat <<EOF
Usage: $0 --vps user@host [--port 22] [--ssh-key /path | --password-auth]
          [--public-url URL] [--auth-local-url URL] [--driver-local-url URL]
          [--auth-login-path /api/auth/login]
          [--settings-value-path /api/admin/settings/value]
          [--deploy-cmd "remote command"]
          [--admin-token TOKEN | --admin-username USER --admin-password PASS]
          [--driver-token TOKEN | --driver-username USER --driver-password PASS]
          [--workflow-general-dispatch-id ID]
          [--workflow-khbl-dispatch-id ID]
          [--workflow-fallback-dispatch-id ID --workflow-fallback-linked-template CODE]
          [--nginx-conf-path /etc/nginx/sites-available/svtms]
          [--backup-cmd /opt/sv-tms/deploy/prod_backup_vps.sh]
          [--rollback-cmd /opt/sv-tms/deploy/prod_rollback_vps.sh]
          [--manual-smoke-status pass|fail|pending]
          [--skip-preflight] [--skip-db-backup] [--skip-nginx-contract]
          [--skip-remote-restart]

Examples:
  $0 --vps root@207.180.245.156 --ssh-key ~/.ssh/id_ed25519 \\
     --deploy-cmd "sudo /opt/sv-tms/deploy/prod_release_split_vps.sh"

  SSHPASS='...' $0 --vps root@207.180.245.156 --password-auth --skip-preflight
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vps) VPS="${2:-}"; shift 2 ;;
    --port) SSH_PORT="${2:-22}"; shift 2 ;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2 ;;
    --password-auth) PASSWORD_AUTH=true; shift ;;
    --public-url) PUBLIC_URL="${2:-}"; shift 2 ;;
    --auth-local-url) AUTH_LOCAL_URL="${2:-}"; shift 2 ;;
    --driver-local-url) DRIVER_LOCAL_URL="${2:-}"; shift 2 ;;
    --auth-login-path) AUTH_LOGIN_PATH="${2:-}"; shift 2 ;;
    --settings-value-path) SETTINGS_VALUE_PATH="${2:-}"; shift 2 ;;
    --nginx-conf-path) NGINX_CONF_PATH="${2:-}"; shift 2 ;;
    --backup-cmd) BACKUP_CMD="${2:-}"; shift 2 ;;
    --rollback-cmd) ROLLBACK_CMD="${2:-}"; shift 2 ;;
    --deploy-cmd) DEPLOY_CMD="${2:-}"; shift 2 ;;
    --admin-username) ADMIN_USERNAME="${2:-}"; shift 2 ;;
    --admin-password) ADMIN_PASSWORD="${2:-}"; shift 2 ;;
    --admin-token) ADMIN_TOKEN="${2:-}"; shift 2 ;;
    --driver-username) DRIVER_USERNAME="${2:-}"; shift 2 ;;
    --driver-password) DRIVER_PASSWORD="${2:-}"; shift 2 ;;
    --driver-token) DRIVER_TOKEN="${2:-}"; shift 2 ;;
    --workflow-general-dispatch-id) WORKFLOW_GENERAL_DISPATCH_ID="${2:-}"; shift 2 ;;
    --workflow-khbl-dispatch-id) WORKFLOW_KHBL_DISPATCH_ID="${2:-}"; shift 2 ;;
    --workflow-fallback-dispatch-id) WORKFLOW_FALLBACK_DISPATCH_ID="${2:-}"; shift 2 ;;
    --workflow-fallback-linked-template) WORKFLOW_FALLBACK_LINKED_TEMPLATE="${2:-}"; shift 2 ;;
    --manual-smoke-status) MANUAL_SMOKE_STATUS="${2:-pending}"; shift 2 ;;
    --skip-preflight) SKIP_PREFLIGHT=true; shift ;;
    --skip-db-backup) SKIP_DB_BACKUP=true; shift ;;
    --skip-nginx-contract) SKIP_NGINX_CONTRACT=true; shift ;;
    --skip-remote-restart) SKIP_REMOTE_RESTART=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

if [[ "${MANUAL_SMOKE_STATUS}" != "pass" && "${MANUAL_SMOKE_STATUS}" != "fail" && "${MANUAL_SMOKE_STATUS}" != "pending" ]]; then
  echo "ERROR: --manual-smoke-status must be one of: pass, fail, pending" >&2
  exit 1
fi

if [[ -z "${VPS}" ]]; then
  echo "ERROR: --vps is required" >&2
  usage
fi

if ${PASSWORD_AUTH}; then
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "ERROR: sshpass not installed (required for --password-auth)" >&2
    exit 1
  fi
  if [[ -z "${SSHPASS:-}" ]]; then
    echo "ERROR: SSHPASS env var is required for --password-auth" >&2
    exit 1
  fi
fi

if [[ ! -x "${DEPLOY_DIR}/post_deploy_microservices_routing_smoke_vps.sh" ]]; then
  echo "ERROR: missing executable smoke script: ${DEPLOY_DIR}/post_deploy_microservices_routing_smoke_vps.sh" >&2
  exit 1
fi
if [[ ! -x "${DEPLOY_DIR}/post_deploy_openapi_split_smoke_vps.sh" ]]; then
  echo "ERROR: missing executable smoke script: ${DEPLOY_DIR}/post_deploy_openapi_split_smoke_vps.sh" >&2
  exit 1
fi
if [[ ! -x "${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" ]]; then
  echo "ERROR: missing executable smoke script: ${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" >&2
  exit 1
fi
if [[ ! -x "${DEPLOY_DIR}/post_deploy_dispatch_workflow_smoke_vps.sh" ]]; then
  echo "ERROR: missing executable smoke script: ${DEPLOY_DIR}/post_deploy_dispatch_workflow_smoke_vps.sh" >&2
  exit 1
fi
if [[ -z "${ADMIN_TOKEN}" && ( -z "${ADMIN_USERNAME}" || -z "${ADMIN_PASSWORD}" ) ]]; then
  echo "ERROR: provide --admin-token or (--admin-username and --admin-password) for dynamic policy smoke" >&2
  exit 1
fi
if [[ -n "${WORKFLOW_FALLBACK_DISPATCH_ID}" && -z "${WORKFLOW_FALLBACK_LINKED_TEMPLATE}" ]]; then
  echo "ERROR: --workflow-fallback-linked-template is required with --workflow-fallback-dispatch-id" >&2
  exit 1
fi
if [[ -n "${WORKFLOW_GENERAL_DISPATCH_ID}${WORKFLOW_KHBL_DISPATCH_ID}${WORKFLOW_FALLBACK_DISPATCH_ID}" ]] \
  && [[ -z "${DRIVER_TOKEN}" && ( -z "${DRIVER_USERNAME}" || -z "${DRIVER_PASSWORD}" ) ]]; then
  echo "ERROR: provide --driver-token or (--driver-username and --driver-password) for dispatch workflow smoke" >&2
  exit 1
fi

SSH_BASE=(ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_KEY}" ]]; then
  SSH_BASE+=(-i "${SSH_KEY}")
fi

ssh_run() {
  if ${PASSWORD_AUTH}; then
    sshpass -e "${SSH_BASE[@]}" "${VPS}" "$@"
  else
    "${SSH_BASE[@]}" "${VPS}" "$@"
  fi
}

run_local() {
  local cmd="$1"
  echo ">>> ${cmd}"
  bash -lc "${cmd}"
}

preflight_checks() {
  if ${SKIP_PREFLIGHT}; then
    echo "Skipping preflight checks."
    return 0
  fi

  run_local "cd '${ROOT_DIR}' && mvn -pl tms-auth-api,tms-driver-app-api -am -DskipTests clean compile"
  run_local "cd '${ROOT_DIR}' && mvn -pl tms-backend -am -Dtest='*IntegrationTest,*IT' -Dsurefire.failIfNoSpecifiedTests=false test"
}

verify_or_create_backup() {
  if ${SKIP_DB_BACKUP}; then
    echo "Skipping DB backup verification."
    return 0
  fi

  echo ">>> Verify backup command exists: ${BACKUP_CMD}"
  ssh_run "test -x '${BACKUP_CMD}'"

  echo ">>> Run backup command"
  ssh_run "sudo '${BACKUP_CMD}'"
}

run_deploy_cmd_if_any() {
  if [[ -z "${DEPLOY_CMD}" ]]; then
    echo "No --deploy-cmd provided; continuing with service restart/smoke validation only."
    return 0
  fi
  echo ">>> Run deploy command on VPS"
  ssh_run "${DEPLOY_CMD}"
}

verify_nginx_contract() {
  if ${SKIP_NGINX_CONTRACT}; then
    echo "Skipping nginx route ownership contract checks."
    return 0
  fi

  echo ">>> Verify nginx route ownership in ${NGINX_CONF_PATH}"
  ssh_run "test -f '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/api/auth/' '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/api/driver/device/' '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/api/driver/' '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/api/driver-app/' '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/api/public/app-version/' '${NGINX_CONF_PATH}'"
  ssh_run "grep -q '/ws-sockjs/' '${NGINX_CONF_PATH}'"
}

restart_and_health_check() {
  if ${SKIP_REMOTE_RESTART}; then
    echo "Skipping remote restart/reload."
  else
    echo ">>> Restart services and reload nginx"
    ssh_run "sudo systemctl restart tms-auth-api tms-driver-app-api"
    ssh_run "sudo systemctl reload nginx || sudo systemctl restart nginx"
  fi

  echo ">>> Verify service active state"
  ssh_run "systemctl is-active tms-auth-api tms-driver-app-api nginx >/dev/null"

  echo ">>> Verify health endpoints"
  ssh_run "curl -fsS '${AUTH_LOCAL_URL}/actuator/health' | grep -q '\"status\":\"UP\"'"
  ssh_run "curl -fsS '${DRIVER_LOCAL_URL}/actuator/health' | grep -q '\"status\":\"UP\"'"
}

run_smoke_gates() {
  mkdir -p "${REPORT_DIR}"
  local ts routing_log openapi_log dynamic_policy_log dispatch_workflow_log
  ts="$(date +%Y%m%d_%H%M%S)"
  routing_log="${REPORT_DIR}/routing_smoke_${ts}.log"
  openapi_log="${REPORT_DIR}/openapi_smoke_${ts}.log"
  dynamic_policy_log="${REPORT_DIR}/dynamic_policy_smoke_${ts}.log"
  dispatch_workflow_log="${REPORT_DIR}/dispatch_workflow_smoke_${ts}.log"

  local ssh_args=()
  if ${PASSWORD_AUTH}; then
    ssh_args+=(--password-auth)
  elif [[ -n "${SSH_KEY}" ]]; then
    ssh_args+=(--ssh-key "${SSH_KEY}")
  fi

  echo ">>> Run routing smoke"
  if ${PASSWORD_AUTH}; then
    SSHPASS="${SSHPASS}" "${DEPLOY_DIR}/post_deploy_microservices_routing_smoke_vps.sh" \
      --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
      --public-url "${PUBLIC_URL}" --auth-local-url "${AUTH_LOCAL_URL}" \
      --driver-local-url "${DRIVER_LOCAL_URL}" | tee "${routing_log}"
  else
    "${DEPLOY_DIR}/post_deploy_microservices_routing_smoke_vps.sh" \
      --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
      --public-url "${PUBLIC_URL}" --auth-local-url "${AUTH_LOCAL_URL}" \
      --driver-local-url "${DRIVER_LOCAL_URL}" | tee "${routing_log}"
  fi
  grep -q "MICROSERVICE_ROUTING_SMOKE_OK" "${routing_log}"

  echo ">>> Run OpenAPI split smoke"
  if ${PASSWORD_AUTH}; then
    SSHPASS="${SSHPASS}" "${DEPLOY_DIR}/post_deploy_openapi_split_smoke_vps.sh" \
      --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
      --auth-local-url "${AUTH_LOCAL_URL}" --driver-local-url "${DRIVER_LOCAL_URL}" \
      | tee "${openapi_log}"
  else
    "${DEPLOY_DIR}/post_deploy_openapi_split_smoke_vps.sh" \
      --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
      --auth-local-url "${AUTH_LOCAL_URL}" --driver-local-url "${DRIVER_LOCAL_URL}" \
      | tee "${openapi_log}"
  fi
  grep -q "OPENAPI_SPLIT_SMOKE_OK" "${openapi_log}"

  echo ">>> Run dynamic driver-policy smoke"
  if ${PASSWORD_AUTH}; then
    if [[ -n "${ADMIN_TOKEN}" ]]; then
      SSHPASS="${SSHPASS}" "${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" \
        --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
        --public-url "${PUBLIC_URL}" --login-path "${AUTH_LOGIN_PATH}" \
        --settings-value-path "${SETTINGS_VALUE_PATH}" \
        --admin-token "${ADMIN_TOKEN}" | tee "${dynamic_policy_log}"
    else
      SSHPASS="${SSHPASS}" "${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" \
        --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
        --public-url "${PUBLIC_URL}" --login-path "${AUTH_LOGIN_PATH}" \
        --settings-value-path "${SETTINGS_VALUE_PATH}" \
        --admin-username "${ADMIN_USERNAME}" --admin-password "${ADMIN_PASSWORD}" \
        | tee "${dynamic_policy_log}"
    fi
  else
    if [[ -n "${ADMIN_TOKEN}" ]]; then
      "${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" \
        --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
        --public-url "${PUBLIC_URL}" --login-path "${AUTH_LOGIN_PATH}" \
        --settings-value-path "${SETTINGS_VALUE_PATH}" \
        --admin-token "${ADMIN_TOKEN}" | tee "${dynamic_policy_log}"
    else
      "${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh" \
        --vps "${VPS}" --port "${SSH_PORT}" "${ssh_args[@]}" \
        --public-url "${PUBLIC_URL}" --login-path "${AUTH_LOGIN_PATH}" \
        --settings-value-path "${SETTINGS_VALUE_PATH}" \
        --admin-username "${ADMIN_USERNAME}" --admin-password "${ADMIN_PASSWORD}" \
        | tee "${dynamic_policy_log}"
    fi
  fi
  grep -q "DYNAMIC_DRIVER_POLICY_SMOKE_OK" "${dynamic_policy_log}"

  if [[ -n "${WORKFLOW_GENERAL_DISPATCH_ID}${WORKFLOW_KHBL_DISPATCH_ID}${WORKFLOW_FALLBACK_DISPATCH_ID}" ]]; then
    echo ">>> Run dispatch workflow smoke"
    local workflow_args=(
      --public-url "${PUBLIC_URL}"
      --login-path "${AUTH_LOGIN_PATH}"
    )
    if [[ -n "${ADMIN_TOKEN}" ]]; then
      workflow_args+=(--admin-token "${ADMIN_TOKEN}")
    else
      workflow_args+=(--admin-username "${ADMIN_USERNAME}" --admin-password "${ADMIN_PASSWORD}")
    fi
    if [[ -n "${DRIVER_TOKEN}" ]]; then
      workflow_args+=(--driver-token "${DRIVER_TOKEN}")
    else
      workflow_args+=(--driver-username "${DRIVER_USERNAME}" --driver-password "${DRIVER_PASSWORD}")
    fi
    if [[ -n "${WORKFLOW_GENERAL_DISPATCH_ID}" ]]; then
      workflow_args+=(--general-dispatch-id "${WORKFLOW_GENERAL_DISPATCH_ID}")
    fi
    if [[ -n "${WORKFLOW_KHBL_DISPATCH_ID}" ]]; then
      workflow_args+=(--khbl-dispatch-id "${WORKFLOW_KHBL_DISPATCH_ID}")
    fi
    if [[ -n "${WORKFLOW_FALLBACK_DISPATCH_ID}" ]]; then
      workflow_args+=(--fallback-dispatch-id "${WORKFLOW_FALLBACK_DISPATCH_ID}")
      workflow_args+=(--fallback-linked-template "${WORKFLOW_FALLBACK_LINKED_TEMPLATE}")
    fi
    "${DEPLOY_DIR}/post_deploy_dispatch_workflow_smoke_vps.sh" "${workflow_args[@]}" | tee "${dispatch_workflow_log}"
    grep -q "DISPATCH_WORKFLOW_SMOKE_OK" "${dispatch_workflow_log}"
    DISPATCH_WORKFLOW_SMOKE_STATUS="pass"
  else
    echo ">>> Dispatch workflow smoke skipped (no workflow dispatch ids provided)"
    DISPATCH_WORKFLOW_SMOKE_STATUS="skipped"
  fi

  echo "Smoke logs:"
  echo "  ${routing_log}"
  echo "  ${openapi_log}"
  echo "  ${dynamic_policy_log}"
  if [[ "${DISPATCH_WORKFLOW_SMOKE_STATUS}" == "pass" ]]; then
    echo "  ${dispatch_workflow_log}"
  fi
}

validate_rollback_readiness() {
  echo ">>> Validate rollback command readiness"
  ssh_run "test -x '${ROLLBACK_CMD}'"
  ssh_run "sudo '${ROLLBACK_CMD}' --help >/dev/null"
}

write_handover_template() {
  mkdir -p "${REPORT_DIR}"
  local ts report
  ts="$(date +%Y%m%d_%H%M%S)"
  report="${REPORT_DIR}/handover_${ts}.md"
  cat > "${report}" <<EOF
# Release Handover (${ts})

## System Status
- auth-api: PASS
- driver-app-api: PASS
- nginx: PASS

## Gate Results
- MICROSERVICE_ROUTING_SMOKE_OK: PASS
- OPENAPI_SPLIT_SMOKE_OK: PASS
- DYNAMIC_DRIVER_POLICY_SMOKE_OK: PASS
- DISPATCH_WORKFLOW_SMOKE_OK: ${DISPATCH_WORKFLOW_SMOKE_STATUS}

## Manual Mobile Smoke (fill by QA/ops)
- status: ${MANUAL_SMOKE_STATUS}
- [ ] login + refresh
- [ ] bootstrap/home
- [ ] current assignment
- [ ] GENERAL dispatch flow from ASSIGNED to COMPLETED
- [ ] KHBL dispatch flow with loading-team handoff
- [ ] POL blocks LOADING -> LOADED until proof upload
- [ ] POD blocks UNLOADING -> UNLOADED until proof upload
- [ ] tracking start/refresh/stop + location update
- [ ] notifications/incidents/safety flows

## 60-Min Monitoring (fill by on-call)
- auth-api log summary:
- driver-app-api log summary:
- nginx error log summary:

## Open Risks / Actions
- risk:
- owner:
- ETA:
EOF

  echo "Handover template created: ${report}"
}

enforce_release_decision_gate() {
  if [[ "${MANUAL_SMOKE_STATUS}" != "pass" ]]; then
    cat <<EOF
NO_GO_DECISION
Reason: manual mobile smoke status is '${MANUAL_SMOKE_STATUS}'.
Policy: default release decision is NO-GO unless manual mobile smoke is PASS.
EOF
    return 1
  fi
}

print_rollback_instructions() {
  local ssh_hint=""
  if [[ -n "${SSH_KEY}" ]]; then
    ssh_hint="-i ${SSH_KEY}"
  fi
  cat <<EOF

If any mandatory check fails, execute rollback immediately:
  ssh -p ${SSH_PORT} ${ssh_hint} ${VPS} "sudo ${ROLLBACK_CMD}"
  ssh -p ${SSH_PORT} ${ssh_hint} ${VPS} "sudo systemctl restart tms-auth-api tms-driver-app-api && sudo systemctl reload nginx"

Then re-run:
  ${DEPLOY_DIR}/post_deploy_microservices_routing_smoke_vps.sh
  ${DEPLOY_DIR}/post_deploy_openapi_split_smoke_vps.sh
  ${DEPLOY_DIR}/post_deploy_dynamic_driver_policy_smoke_vps.sh
  ${DEPLOY_DIR}/post_deploy_dispatch_workflow_smoke_vps.sh
EOF
}

main() {
  preflight_checks
  verify_or_create_backup
  run_deploy_cmd_if_any
  verify_nginx_contract
  restart_and_health_check
  run_smoke_gates
  validate_rollback_readiness
  write_handover_template
  enforce_release_decision_gate
  print_rollback_instructions
  echo "PRODUCTION_MORNING_RELEASE_PLAN_OK"
}

main "$@"
