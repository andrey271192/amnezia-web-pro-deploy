#!/usr/bin/env bash
# Legacy GHCR installer. Default public install now goes through quick-install.sh
# -> amnezia_web-PRO_test/install.sh to avoid GHCR 403 for users without package access.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/lib-compose-v2.sh"

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Запустите от root: sudo bash scripts/install.sh"
    exit 1
  fi
}

need_docker() {
  command -v docker >/dev/null 2>&1 || {
    echo "Нужен Docker."
    exit 1
  }
  docker info >/dev/null 2>&1 || {
    echo "Docker daemon недоступен."
    exit 1
  }
}

need_root
need_docker
ensure_compose_v2 || exit 1
COMPOSE=(docker compose)

if [[ "${USE_GHCR:-0}" != "1" ]]; then
  echo "Этот сценарий использует private GHCR image и может дать 403 Forbidden."
  echo "Для обычной установки используйте:"
  echo "  curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo bash"
  echo ""
  echo "Если точно нужен старый GHCR-режим, запустите:"
  echo "  USE_GHCR=1 sudo -E bash scripts/install.sh"
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Создайте файл .env из .env.example и вставьте GHCR_* из закрытого поста Boosty:"
  echo "  cp .env.example .env && nano .env"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

# Убираем CR и пробелы по краям (часто после копирования из Boosty/Windows)
trim_crlf() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}
GHCR_IMAGE="$(trim_crlf "${GHCR_IMAGE:-}")"
IMAGE_TAG="$(trim_crlf "${IMAGE_TAG:-}")"
GHCR_USERNAME="$(trim_crlf "${GHCR_USERNAME:-}")"
GHCR_TOKEN="$(trim_crlf "${GHCR_TOKEN:-}")"
ADMIN_PASSWORD="$(trim_crlf "${ADMIN_PASSWORD:-}")"

: "${GHCR_IMAGE:?Укажите GHCR_IMAGE в .env}"
: "${IMAGE_TAG:?Укажите IMAGE_TAG в .env}"
: "${GHCR_USERNAME:?Укажите GHCR_USERNAME в .env}"
: "${GHCR_TOKEN:?Укажите GHCR_TOKEN в .env}"

echo "→ docker login ghcr.io ..."
printf '%s\n' "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin

echo "→ pull ${GHCR_IMAGE}:${IMAGE_TAG}"
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

echo "→ up -d"
UP_ARGS=(up -d)
if [[ "${RESET_PANEL_PASSWORD}" == "1" ]]; then
  UP_ARGS+=(--force-recreate)
fi
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" "${UP_ARGS[@]}"

IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
echo ""
echo "=== Готово ==="
echo "Панель: http://${IP:-YOUR_SERVER_IP}:${HOST_PORT:-8080}"
echo "Обновление: sudo bash ${ROOT_DIR}/scripts/update.sh"
