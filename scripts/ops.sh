#!/usr/bin/env bash
set -euo pipefail          # stop on errors, unset variables, and failed pipes

cd "$(dirname "$0")/.."    # always run from the repo root, wherever it's called from

API_URL="${API_URL:-http://localhost:8080}"

die() { echo "ERROR: $*" >&2; exit 1; }

# See if a container engine is already installed, and specify which to use
if [[ -z "${ENGINE:-}" ]]; then
  if   command -v podman >/dev/null; then ENGINE=podman
  elif command -v docker >/dev/null; then ENGINE=docker
  else die "Container runtime not found. Cannot run container workload."
  fi
fi
COMPOSE=("$ENGINE" compose)

wait_healthy() {
  for _ in $(seq 1 30); do
    curl -fsS --max-time 2 "$API_URL/health" >/dev/null 2>&1 && return 0
    sleep 2
  done
  die "API healthcheck failed. See logs for details."
}

cmd_up() {
  [[ -f .env ]] || die ".env not found. Ensure it exists and that all required variables are set."
  "${COMPOSE[@]}" up -d --build
  wait_healthy
  echo "API service is up and accessible at: $API_URL"
}

cmd_down() {
  "${COMPOSE[@]}" down
  echo "API service has been stopped."
}

cmd_status() {
  "${COMPOSE[@]}" ps
  if curl -fsS --max-time 3 "$API_URL/health" >/dev/null 2>&1; then
    echo "API health: OK"
  else
    die "API healthcheck failed. Confirm that API service is active and check logs if necessary."
  fi
}

cmd_logs() {
  trap 'echo; exit 0' INT
  "${COMPOSE[@]}" logs -f --tail=100 api 2>/dev/null || true
}

pass() { echo "PASS: $1"; }
fail() { die "FAIL: $1"; }

cmd_smoke() {
  local user_json user_id list

  curl -fsS --max-time 5 "$API_URL/health" >/dev/null || fail "GET /health"
  pass "GET /health"

  user_json=$(curl -fsS --max-time 5 -X POST "$API_URL/users" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"smoke-$(date +%s)\"}") || fail "POST /users"
  user_id=$(printf '%s' "$user_json" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')
  [[ -n "$user_id" ]] || fail "POST /users returned no id: $user_json"
  pass "POST /users (id=$user_id)"

  curl -fsS --max-time 5 -X POST "$API_URL/notifications" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":$user_id,\"title\":\"smoke test\",\"body\":\"hello\"}" \
    >/dev/null || fail "POST /notifications"
  pass "POST /notifications"

  list=$(curl -fsS --max-time 5 "$API_URL/notifications?user_id=$user_id") \
    || fail "GET /notifications"
  [[ "$list" == *'"title":"smoke test"'* ]] || fail "notification not found in: $list"
  pass "GET /notifications"

  echo "All smoke checks passed."
}

case "${1:-}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  logs)   cmd_logs ;;
  smoke)  cmd_smoke ;;
  *)      echo "Supported commands: $0 {up|down|status|logs|smoke}" >&2; exit 2 ;;
esac