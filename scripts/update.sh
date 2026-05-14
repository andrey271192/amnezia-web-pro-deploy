#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Запустите от root."
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Нужен docker compose."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

trim_crlf() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}
GHCR_USERNAME="$(trim_crlf "${GHCR_USERNAME:-}")"
GHCR_TOKEN="$(trim_crlf "${GHCR_TOKEN:-}")"

printf '%s\n' "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d

echo "Обновлено."
