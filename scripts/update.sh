#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/lib-compose-v2.sh"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Запустите от root."
  exit 1
fi

ensure_compose_v2 || exit 1
COMPOSE=(docker compose)

if [[ "${USE_GHCR:-0}" != "1" ]]; then
  echo "Этот update.sh относится к legacy GHCR-режиму и может дать 403 Forbidden."
  echo "Для source-установки обновляйтесь из панели или вручную:"
  echo "  cd /opt/amnezia-web-pro"
  echo "  git pull"
  echo "  docker compose build"
  echo "  docker compose up -d"
  echo ""
  echo "Если точно нужен старый GHCR-режим, запустите:"
  echo "  USE_GHCR=1 sudo -E bash scripts/update.sh"
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
ADMIN_PASSWORD="$(trim_crlf "${ADMIN_PASSWORD:-}")"

printf '%s\n' "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull

RESET_PANEL_PASSWORD=0
if [[ -n "${ADMIN_PASSWORD}" ]]; then
  echo "→ ADMIN_PASSWORD задан — сбрасываю старый пароль панели в volume."
  "${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" run --rm --no-deps --entrypoint sh panel -lc '
    set -eu
    if [ -f /data/password.hash ]; then
      cp -p /data/password.hash "/data/password.hash.bak.$(date -u +%Y%m%dT%H%M%SZ)" 2>/dev/null || true
      rm -f /data/password.hash
      rm -f /data/session.secret
    fi
  '
  RESET_PANEL_PASSWORD=1
fi

UP_ARGS=(up -d)
if [[ "${RESET_PANEL_PASSWORD}" == "1" ]]; then
  UP_ARGS+=(--force-recreate)
fi
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" "${UP_ARGS[@]}"

echo "Обновлено."
