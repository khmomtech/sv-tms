#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/.local-dev/logs"
PID_DIR="${ROOT_DIR}/.local-dev/pids"
ENV_FILE="${ROOT_DIR}/scripts/local-split-dev.env"
LOCAL_DEV_COMPOSE_FILE="${ROOT_DIR}/docker-compose.local-dev.yml"

mkdir -p "${LOG_DIR}" "${PID_DIR}"

JWT_ACCESS_SECRET_DEFAULT="SuperSecureKeyForJWTAuthentication2024SuperSecureKeyForJWT"
JWT_REFRESH_SECRET_DEFAULT="SuperSecureKeyForJWTAuthentication2024SuperSecureKeyForJWT-REFRESH"

JWT_ACCESS_SECRET="${JWT_ACCESS_SECRET:-$JWT_ACCESS_SECRET_DEFAULT}"
JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET:-$JWT_REFRESH_SECRET_DEFAULT}"
APP_DRIVER_SKIP_DEVICE_CHECK="${APP_DRIVER_SKIP_DEVICE_CHECK:-true}"
APP_DRIVER_LOGIN_BYPASS="${APP_DRIVER_LOGIN_BYPASS:-true}"
SKIP_BUILD="${SKIP_BUILD:-0}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

service_pid_file() {
  local name="$1"
  printf '%s/%s.pid' "${PID_DIR}" "${name}"
}

service_log_file() {
  local name="$1"
  printf '%s/%s.log' "${LOG_DIR}" "${name}"
}

service_port() {
  local name="$1"
  case "${name}" in
    tms-backend)
      printf '8080'
      ;;
    tms-auth-api)
      printf '8083'
      ;;
    tms-driver-app-api)
      printf '8084'
      ;;
    tms-frontend)
      printf '4200'
      ;;
    *)
      return 1
      ;;
  esac
}

service_jar_path() {
  local name="$1"
  case "${name}" in
    tms-backend)
      printf '%s/tms-backend/target/tms-backend-0.0.1-SNAPSHOT-exec.jar' "${ROOT_DIR}"
      ;;
    tms-auth-api)
      printf '%s/tms-auth-api/target/tms-auth-api-0.0.1-SNAPSHOT.jar' "${ROOT_DIR}"
      ;;
    tms-driver-app-api)
      printf '%s/tms-driver-app-api/target/tms-driver-app-api-0.0.1-SNAPSHOT.jar' "${ROOT_DIR}"
      ;;
    *)
      return 1
      ;;
  esac
}

shared_split_api_config_path() {
  printf '%s/tms-backend-shared/src/main/resources/application-backend-common.properties' "${ROOT_DIR}"
}

listener_pid_for_port() {
  local port="$1"
  lsof -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null | head -n 1
}

normalize_service_name() {
  local name="${1:-}"
  case "${name}" in
    backend|api|tms-backend)
      printf 'tms-backend'
      ;;
    auth|auth-api|tms-auth-api)
      printf 'tms-auth-api'
      ;;
    driver|driver-api|tms-driver-app-api)
      printf 'tms-driver-app-api'
      ;;
    frontend|web|ui|tms-frontend)
      printf 'tms-frontend'
      ;;
    *)
      return 1
      ;;
  esac
}

service_label() {
  local name="$1"
  case "${name}" in
    tms-backend)
      printf 'backend'
      ;;
    tms-auth-api)
      printf 'auth-api'
      ;;
    tms-driver-app-api)
      printf 'driver-api'
      ;;
    tms-frontend)
      printf 'frontend'
      ;;
    *)
      return 1
      ;;
  esac
}

service_workdir() {
  local name="$1"
  case "${name}" in
    tms-backend|tms-auth-api|tms-driver-app-api|tms-frontend)
      printf '%s/%s' "${ROOT_DIR}" "${name}"
      ;;
    *)
      return 1
      ;;
  esac
}

service_start_mode() {
  local name="$1"
  local jar_path
  case "${name}" in
    tms-backend|tms-auth-api|tms-driver-app-api)
      jar_path="$(service_jar_path "${name}")"
      if [[ "${SKIP_BUILD}" == "1" && -f "${jar_path}" ]]; then
        printf 'jar'
      else
        printf 'maven'
      fi
      ;;
    tms-frontend)
      printf 'npm'
      ;;
    *)
      return 1
      ;;
  esac
}

runtime_mode_from_command() {
  local command="$1"
  case "${command}" in
    *"java -jar"*)
      printf 'jar'
      ;;
    *"spring-boot:run"*|*"org.codehaus.plexus.classworlds.launcher.Launcher"*|*"AuthApiApplication"*|*"DriverAppApiApplication"*|*"com.svtrucking.logistics.Application"*)
      printf 'maven'
      ;;
    *"ng serve"*|*"npm run start"*)
      printf 'npm'
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

compact_command() {
  local command="$1"
  case "${command}" in
    *"/tms-backend-0.0.1-SNAPSHOT-exec.jar"*)
      printf 'java -jar tms-backend-exec.jar'
      ;;
    *"AuthApiApplication"*)
      printf 'mvn spring-boot:run (tms-auth-api)'
      ;;
    *"DriverAppApiApplication"*)
      printf 'mvn spring-boot:run (tms-driver-app-api)'
      ;;
    *"com.svtrucking.logistics.Application"*)
      printf 'mvn spring-boot:run (tms-backend)'
      ;;
    *"/tms-auth-api-0.0.1-SNAPSHOT.jar"*--spring.config.additional-location=*)
      printf 'java -jar tms-auth-api.jar --spring.config.additional-location=application-backend-common.properties'
      ;;
    *"/tms-auth-api-0.0.1-SNAPSHOT.jar"*)
      printf 'java -jar tms-auth-api.jar'
      ;;
    *"/tms-driver-app-api-0.0.1-SNAPSHOT.jar"*--spring.config.additional-location=*)
      printf 'java -jar tms-driver-app-api.jar --spring.config.additional-location=application-backend-common.properties'
      ;;
    *"/tms-driver-app-api-0.0.1-SNAPSHOT.jar"*)
      printf 'java -jar tms-driver-app-api.jar'
      ;;
    *"spring-boot:run"*"/tms-auth-api"*)
      printf 'mvn spring-boot:run (tms-auth-api)'
      ;;
    *"spring-boot:run"*"/tms-driver-app-api"*)
      printf 'mvn spring-boot:run (tms-driver-app-api)'
      ;;
    *"spring-boot:run"*"/tms-backend"*)
      printf 'mvn spring-boot:run (tms-backend)'
      ;;
    *"ng serve"*|*"npm run start"*)
      printf 'ng serve --proxy-config proxy.conf.cjs --port 4200'
      ;;
    *)
      printf '%s' "${command}"
      ;;
  esac
}

is_running() {
  local name="$1"
  local pid_file
  pid_file="$(service_pid_file "${name}")"
  [[ -f "${pid_file}" ]] || return 1
  local pid
  pid="$(<"${pid_file}")"
  kill -0 "${pid}" 2>/dev/null
}

refresh_pid_file_from_listener() {
  local name="$1"
  local port pid listener_pid
  port="$(service_port "${name}")"
  pid="$(listener_pid_for_port "${port}" || true)"
  if [[ -n "${pid}" ]]; then
    echo "${pid}" >"$(service_pid_file "${name}")"
    return 0
  fi
  return 1
}

stop_service() {
  local name="$1"
  local pid_file
  pid_file="$(service_pid_file "${name}")"
  refresh_pid_file_from_listener "${name}" >/dev/null 2>&1 || true
  if ! [[ -f "${pid_file}" ]]; then
    return 0
  fi
  local pid
  pid="$(<"${pid_file}")"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}" 2>/dev/null || true
    sleep 1
    if kill -0 "${pid}" 2>/dev/null; then
      kill -9 "${pid}" 2>/dev/null || true
    fi
  fi
  rm -f "${pid_file}"
}

start_service() {
  local name="$1"
  local workdir="$2"
  local command="$3"

  if is_running "${name}"; then
    echo "${name} already running"
    return 0
  fi

  local log_file pid_file
  log_file="$(service_log_file "${name}")"
  pid_file="$(service_pid_file "${name}")"

  (
    cd "${workdir}"
    nohup bash -lc "exec ${command}" >"${log_file}" 2>&1 &
    echo $! >"${pid_file}"
  )

  echo "started ${name} -> ${log_file}"
}

wait_for_http() {
  local url="$1"
  local timeout_seconds="${2:-90}"
  local elapsed=0
  until curl -fsS "${url}" >/dev/null 2>&1; do
    sleep 2
    elapsed=$((elapsed + 2))
    if (( elapsed >= timeout_seconds )); then
      echo "timeout waiting for ${url}" >&2
      return 1
    fi
  done
}

build_required_artifacts() {
  if [[ "${SKIP_BUILD}" == "1" ]]; then
    echo "SKIP_BUILD=1, skipping Maven install steps"
    return 0
  fi

  (
    cd "${ROOT_DIR}/tms-backend-shared"
    mvn -q -Dmaven.test.skip=true install
  )

  (
    cd "${ROOT_DIR}/tms-backend"
    mvn -q -Dmaven.test.skip=true install
  )
}

build_required_artifacts_for_service() {
  local name="$1"
  case "${name}" in
    tms-auth-api|tms-driver-app-api)
      build_required_artifacts
      ;;
    tms-backend|tms-frontend)
      if [[ "${SKIP_BUILD}" == "1" ]]; then
        echo "SKIP_BUILD=1, skipping pre-start build for ${name}"
      else
        echo "skipping pre-start Maven install for ${name}"
      fi
      ;;
    *)
      echo "unknown service: ${name}" >&2
      return 1
      ;;
  esac
}

docker_compose_local_dev() {
  (
    cd "${ROOT_DIR}"
    COMPOSE_IGNORE_ORPHANS=True docker compose -f "${LOCAL_DEV_COMPOSE_FILE}" "$@"
  )
}

start_infra() {
  docker_compose_local_dev up -d mysql redis mongo
}

start_named_service() {
  local name="$1"
  local jar_path shared_config_path
  shared_config_path="$(shared_split_api_config_path)"
  case "${name}" in
    tms-backend)
      jar_path="$(service_jar_path "${name}")"
      start_service \
        "tms-backend" \
        "${ROOT_DIR}/tms-backend" \
        "$(if [[ "${SKIP_BUILD}" == "1" && -f "${jar_path}" ]]; then
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' java -jar '%s'" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}" "${jar_path}";
          else
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' mvn -Dmaven.test.skip=true spring-boot:run" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}";
          fi)"
      ;;
    tms-auth-api)
      jar_path="$(service_jar_path "${name}")"
      start_service \
        "tms-auth-api" \
        "${ROOT_DIR}/tms-auth-api" \
        "$(if [[ "${SKIP_BUILD}" == "1" && -f "${jar_path}" ]]; then
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' java -jar '%s' --spring.config.additional-location='optional:file:%s'" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}" "${jar_path}" "${shared_config_path}";
          else
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' mvn -Dmaven.test.skip=true spring-boot:run" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}";
          fi)"
      ;;
    tms-driver-app-api)
      jar_path="$(service_jar_path "${name}")"
      start_service \
        "tms-driver-app-api" \
        "${ROOT_DIR}/tms-driver-app-api" \
        "$(if [[ "${SKIP_BUILD}" == "1" && -f "${jar_path}" ]]; then
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' java -jar '%s' --spring.config.additional-location='optional:file:%s'" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}" "${jar_path}" "${shared_config_path}";
          else
            printf "env JWT_ACCESS_SECRET='%s' JWT_REFRESH_SECRET='%s' APP_DRIVER_SKIP_DEVICE_CHECK='%s' APP_DRIVER_LOGIN_BYPASS='%s' mvn -Dmaven.test.skip=true spring-boot:run" \
              "${JWT_ACCESS_SECRET}" "${JWT_REFRESH_SECRET}" "${APP_DRIVER_SKIP_DEVICE_CHECK}" "${APP_DRIVER_LOGIN_BYPASS}";
          fi)"
      ;;
    tms-frontend)
      start_service \
        "tms-frontend" \
        "${ROOT_DIR}/tms-frontend" \
        "npm run start -- --port 4200"
      ;;
    *)
      echo "unknown service: ${name}" >&2
      return 1
      ;;
  esac
}

env_one() {
  local name="$1"
  local label mode jar_path
  label="$(service_label "${name}")"
  mode="$(service_start_mode "${name}")"
  printf '%s\n' "service=${label}"
  printf '%s\n' "launch_mode=${mode}"
  printf '%s\n' "workdir=$(service_workdir "${name}")"
  printf '%s\n' "port=$(service_port "${name}")"
  printf '%s\n' "log=$(service_log_file "${name}")"
  printf '%s\n' "pid_file=$(service_pid_file "${name}")"
  if [[ "${name}" == "tms-backend" || "${name}" == "tms-auth-api" || "${name}" == "tms-driver-app-api" ]]; then
    jar_path="$(service_jar_path "${name}")"
    printf '%s\n' "jar=${jar_path}"
    printf '%s\n' "jar_exists=$(if [[ -f "${jar_path}" ]]; then echo yes; else echo no; fi)"
  fi
  printf '%s\n' "skip_build=${SKIP_BUILD}"
  printf '%s\n' "jwt_access_secret_source=$(if [[ "${JWT_ACCESS_SECRET}" == "${JWT_ACCESS_SECRET_DEFAULT}" ]]; then echo default; else echo custom; fi)"
  printf '%s\n' "jwt_refresh_secret_source=$(if [[ "${JWT_REFRESH_SECRET}" == "${JWT_REFRESH_SECRET_DEFAULT}" ]]; then echo default; else echo custom; fi)"
  printf '%s\n' "app_driver_skip_device_check=${APP_DRIVER_SKIP_DEVICE_CHECK}"
  printf '%s\n' "app_driver_login_bypass=${APP_DRIVER_LOGIN_BYPASS}"
  if [[ "${name}" == "tms-auth-api" || "${name}" == "tms-driver-app-api" ]]; then
    printf '%s\n' "shared_config=$(shared_split_api_config_path)"
  fi
}

env_all() {
  local name
  for name in tms-backend tms-auth-api tms-driver-app-api tms-frontend; do
    env_one "${name}"
    echo
  done
}

ps_one() {
  local name="$1"
  local long_output="${2:-0}"
  local label port pid_file pid listener_pid command mode
  label="$(service_label "${name}")"
  port="$(service_port "${name}")"
  pid_file="$(service_pid_file "${name}")"
  mode="$(service_start_mode "${name}")"
  pid="-"
  refresh_pid_file_from_listener "${name}" >/dev/null 2>&1 || true
  if [[ -f "${pid_file}" ]]; then
    pid="$(<"${pid_file}")"
  fi
  listener_pid="$(listener_pid_for_port "${port}" || true)"
  if [[ -n "${listener_pid}" ]]; then
    pid="${listener_pid}"
  fi
  command="-"
  if [[ "${pid}" != "-" ]] && kill -0 "${pid}" 2>/dev/null; then
    command="$(ps -p "${pid}" -o command= 2>/dev/null | sed 's/^[[:space:]]*//')"
    mode="$(runtime_mode_from_command "${command}")"
    if [[ "${long_output}" != "1" ]]; then
      command="$(compact_command "${command}")"
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "${label}" "${port}" "${pid}" "${mode}" "${command}"
}

ps_all() {
  local long_output="${1:-0}"
  printf '%s\t%s\t%s\t%s\t%s\n' "service" "port" "pid" "mode" "command"
  ps_one "tms-backend" "${long_output}"
  ps_one "tms-auth-api" "${long_output}"
  ps_one "tms-driver-app-api" "${long_output}"
  ps_one "tms-frontend" "${long_output}"
}

wait_for_named_service() {
  local name="$1"
  case "${name}" in
    tms-backend)
      wait_for_http "http://localhost:8080/actuator/health" 120
      ;;
    tms-auth-api)
      wait_for_http "http://localhost:8083/actuator/health" 120
      ;;
    tms-driver-app-api)
      wait_for_http "http://localhost:8084/actuator/health" 120
      ;;
    tms-frontend)
      wait_for_http "http://localhost:4200/login" 120
      ;;
    *)
      echo "unknown service: ${name}" >&2
      return 1
      ;;
  esac
  refresh_pid_file_from_listener "${name}" >/dev/null 2>&1 || true
}

start_all() {
  start_infra
  build_required_artifacts

  start_named_service "tms-backend"
  start_named_service "tms-auth-api"
  start_named_service "tms-driver-app-api"
  start_named_service "tms-frontend"

  wait_for_named_service "tms-backend"
  wait_for_named_service "tms-auth-api"
  wait_for_named_service "tms-driver-app-api"
  wait_for_named_service "tms-frontend"

  status_all
}

stop_all() {
  stop_service "tms-backend"
  stop_service "tms-auth-api"
  stop_service "tms-driver-app-api"
  stop_service "tms-frontend"
}

clean_all() {
  stop_all
  rm -f "${PID_DIR}"/*.pid 2>/dev/null || true
  rm -f "${LOG_DIR}"/*.log 2>/dev/null || true
  docker_compose_local_dev down
}

status_all() {
  echo "backend: $(curl -fsS http://localhost:8080/actuator/health 2>/dev/null || echo DOWN)"
  echo "frontend: $(curl -fsS http://localhost:4200/login >/dev/null 2>&1 && echo UP || echo DOWN)"
  echo "auth-api: $(curl -fsS http://localhost:8083/actuator/health 2>/dev/null || echo DOWN)"
  echo "driver-api: $(curl -fsS http://localhost:8084/actuator/health 2>/dev/null || echo DOWN)"
}

status_one() {
  local name="$1"
  case "${name}" in
    tms-backend)
      echo "backend: $(curl -fsS http://localhost:8080/actuator/health 2>/dev/null || echo DOWN)"
      ;;
    tms-auth-api)
      echo "auth-api: $(curl -fsS http://localhost:8083/actuator/health 2>/dev/null || echo DOWN)"
      ;;
    tms-driver-app-api)
      echo "driver-api: $(curl -fsS http://localhost:8084/actuator/health 2>/dev/null || echo DOWN)"
      ;;
    tms-frontend)
      echo "frontend: $(curl -fsS http://localhost:4200/login >/dev/null 2>&1 && echo UP || echo DOWN)"
      ;;
    *)
      echo "unknown service: ${name}" >&2
      return 1
      ;;
  esac
}

doctor_one() {
  local name="$1"
  local port pid_file log_file pid runtime_status listener_status listener_pid
  port="$(service_port "${name}")"
  pid_file="$(service_pid_file "${name}")"
  log_file="$(service_log_file "${name}")"
  runtime_status="DOWN"
  listener_status="DOWN"
  pid="-"
  listener_pid="-"

  refresh_pid_file_from_listener "${name}" >/dev/null 2>&1 || true

  if [[ -f "${pid_file}" ]]; then
    pid="$(<"${pid_file}")"
    if kill -0 "${pid}" 2>/dev/null; then
      runtime_status="RUNNING"
    else
      runtime_status="STALE_PID"
    fi
  fi

  listener_pid="$(listener_pid_for_port "${port}" || true)"
  if [[ -n "${listener_pid}" ]]; then
    listener_status="LISTENING"
  fi

  printf '%s\n' "service=${name}"
  printf '%s\n' "port=${port}"
  printf '%s\n' "pid_file=${pid_file}"
  printf '%s\n' "pid=${pid}"
  printf '%s\n' "process=${runtime_status}"
  printf '%s\n' "listener=${listener_status}"
  printf '%s\n' "listener_pid=${listener_pid}"
  printf '%s\n' "log=${log_file}"
  if [[ -f "${log_file}" ]]; then
    printf '%s\n' "log_exists=yes"
  else
    printf '%s\n' "log_exists=no"
  fi
}

doctor_all() {
  for name in tms-backend tms-auth-api tms-driver-app-api tms-frontend; do
    doctor_one "${name}"
    echo
  done
}

logs_all() {
  for name in tms-auth-api tms-driver-app-api tms-frontend; do
    local local_file
    local_file="$(service_log_file "${name}")"
    echo "===== ${name} ====="
    if [[ -f "${local_file}" ]]; then
      tail -n 40 "${local_file}"
    else
      echo "no log file"
    fi
  done
}

logs_one() {
  local name="$1"
  local follow="${2:-0}"
  local local_file
  local_file="$(service_log_file "${name}")"
  if [[ -f "${local_file}" ]]; then
    if [[ "${follow}" == "1" ]]; then
      tail -n 80 -f "${local_file}"
    else
      tail -n 80 "${local_file}"
    fi
  else
    echo "no log file for ${name}"
  fi
}

smoke_all() {
  local code
  curl -fsS http://localhost:8080/actuator/health >/dev/null
  curl -fsS http://localhost:8083/actuator/health >/dev/null
  curl -fsS http://localhost:8084/actuator/health >/dev/null
  curl -fsS http://localhost:4200/login >/dev/null

  code="$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:4200/api/driver/device/request-approval -H 'Content-Type: application/json' -d '{}')"
  case "${code}" in
    200|400|401|403|415) ;;
    *) echo "unexpected frontend->auth proxy status: ${code}" >&2; return 1 ;;
  esac

  code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:4200/api/driver-app/bootstrap)"
  case "${code}" in
    200|401|403) ;;
    *) echo "unexpected frontend->driver proxy status: ${code}" >&2; return 1 ;;
  esac

  code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:4200/api/public/runtime-info)"
  case "${code}" in
    200|401|403|404) ;;
    *) echo "unexpected frontend->backend proxy status: ${code}" >&2; return 1 ;;
  esac

  echo "smoke: PASS"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/local-split-dev.sh start
  ./scripts/local-split-dev.sh start backend|auth|driver|frontend
  ./scripts/local-split-dev.sh stop
  ./scripts/local-split-dev.sh stop backend|auth|driver|frontend
  ./scripts/local-split-dev.sh restart
  ./scripts/local-split-dev.sh restart backend|auth|driver|frontend
  ./scripts/local-split-dev.sh status
  ./scripts/local-split-dev.sh status backend|auth|driver|frontend
  ./scripts/local-split-dev.sh doctor
  ./scripts/local-split-dev.sh doctor backend|auth|driver|frontend
  ./scripts/local-split-dev.sh ps
  ./scripts/local-split-dev.sh ps --long
  ./scripts/local-split-dev.sh ps backend|auth|driver|frontend
  ./scripts/local-split-dev.sh env
  ./scripts/local-split-dev.sh env backend|auth|driver|frontend
  ./scripts/local-split-dev.sh logs
  ./scripts/local-split-dev.sh logs backend|auth|driver|frontend
  ./scripts/local-split-dev.sh logs -f backend|auth|driver|frontend
  ./scripts/local-split-dev.sh smoke
  ./scripts/local-split-dev.sh clean

Optional env:
  JWT_ACCESS_SECRET
  JWT_REFRESH_SECRET
  APP_DRIVER_SKIP_DEVICE_CHECK
  APP_DRIVER_LOGIN_BYPASS
  SKIP_BUILD=1
EOF
}

cmd="${1:-status}"
case "${cmd}" in
  start)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      if [[ "${service_name}" != "tms-frontend" ]]; then
        start_infra
      fi
      build_required_artifacts_for_service "${service_name}"
      start_named_service "${service_name}"
      wait_for_named_service "${service_name}"
      status_one "${service_name}"
    else
      start_all
    fi
    ;;
  stop)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      stop_service "${service_name}"
    else
      stop_all
    fi
    ;;
  restart)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      stop_service "${service_name}"
      start_infra
      build_required_artifacts_for_service "${service_name}"
      start_named_service "${service_name}"
      wait_for_named_service "${service_name}"
      status_one "${service_name}"
    else
      stop_all
      start_all
    fi
    ;;
  status)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      status_one "${service_name}"
    else
      status_all
    fi
    ;;
  doctor)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      doctor_one "${service_name}"
    else
      doctor_all
    fi
    ;;
  ps)
    if [[ $# -ge 2 && "${2}" == "--long" ]]; then
      if [[ $# -ge 3 ]]; then
        service_name="$(normalize_service_name "${3}")"
        printf '%s\t%s\t%s\t%s\t%s\n' "service" "port" "pid" "mode" "command"
        ps_one "${service_name}" 1
      else
        ps_all 1
      fi
    elif [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      printf '%s\t%s\t%s\t%s\t%s\n' "service" "port" "pid" "mode" "command"
      ps_one "${service_name}" 0
    else
      ps_all 0
    fi
    ;;
  env)
    if [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      env_one "${service_name}"
    else
      env_all
    fi
    ;;
  logs)
    if [[ $# -ge 2 && "${2}" == "-f" ]]; then
      service_name="$(normalize_service_name "${3}")"
      logs_one "${service_name}" 1
    elif [[ $# -ge 2 ]]; then
      service_name="$(normalize_service_name "${2}")"
      logs_one "${service_name}" 0
    else
      logs_all
    fi
    ;;
  smoke)
    smoke_all
    ;;
  clean)
    clean_all
    ;;
  *)
    usage
    exit 1
    ;;
esac
