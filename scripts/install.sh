#!/usr/bin/env bash
# Установка Pro с приватного GHCR (без исходников). Публичный репозиторий — только этот скрипт и compose.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

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

need_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
    return
  fi
  echo "Нужен Docker Compose v2 (docker compose)."
  exit 1
}

need_root
need_docker
need_compose

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

: "${GHCR_IMAGE:?Укажите GHCR_IMAGE в .env}"
: "${IMAGE_TAG:?Укажите IMAGE_TAG в .env}"
: "${GHCR_USERNAME:?Укажите GHCR_USERNAME в .env}"
: "${GHCR_TOKEN:?Укажите GHCR_TOKEN в .env}"

echo "→ docker login ghcr.io ..."
printf '%s\n' "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin

echo "→ pull ${GHCR_IMAGE}:${IMAGE_TAG}"
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull

echo "→ up -d"
"${COMPOSE[@]}" -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d

IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
echo ""
echo "=== Готово ==="
echo "Панель: http://${IP:-YOUR_SERVER_IP}:${HOST_PORT:-8080}"
echo "Обновление: sudo bash ${ROOT_DIR}/scripts/update.sh"
