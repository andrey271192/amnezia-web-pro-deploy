#!/usr/bin/env bash
# One-command installer kept for subscriber links. Default path installs from
# the private source repo using GITHUB_TOKEN, not the legacy GHCR image.
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main}"
SOURCE_INSTALL_URL="${SOURCE_INSTALL_URL:-https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh}"

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Запустите с GITHUB_TOKEN:"
    echo "curl -fsSL -H \"Authorization: Bearer \${GITHUB_TOKEN}\" ${RAW_BASE}/quick-install.sh | sudo -E bash"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Нужна утилита: $1"
    exit 1
  }
}

curl_auth_args() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    printf '%s\n' -H "Authorization: Bearer ${GITHUB_TOKEN}"
  fi
}

need_root
need_cmd curl

if [[ "${USE_GHCR:-0}" != "1" ]]; then
  echo "→ GHCR-установка отключена: старый private image часто даёт 403 Forbidden."
  echo "→ Ставлю Amnezia Web PRO из private GitHub source: ${SOURCE_INSTALL_URL}"
  echo "→ Для старого GHCR-сценария запустите: USE_GHCR=1 curl ... | sudo -E bash"
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "Нужен GITHUB_TOKEN с доступом к private repo andrey271192/amnezia_web-PRO_test."
    echo "Пример: export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'"
    exit 1
  fi
  echo ""
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  mapfile -t _curl_auth < <(curl_auth_args)
  curl -fsSL "${_curl_auth[@]}" "${SOURCE_INSTALL_URL}" -o "$tmp"
  exec bash "$tmp"
fi

DEPLOY_REPO="${DEPLOY_REPO:-https://github.com/andrey271192/amnezia-web-pro-deploy.git}"
INSTALL_ROOT="${INSTALL_ROOT:-/opt/amnezia-web-pro-deploy}"

DEFAULT_GHCR_IMAGE="${DEFAULT_GHCR_IMAGE:-ghcr.io/andrey271192/amnezia-admin-pro}"
DEFAULT_GHCR_USERNAME="${DEFAULT_GHCR_USERNAME:-andrey271192}"

need_cmd docker

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon недоступен. Запустите Docker и повторите."
  exit 1
fi

trim() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

if ! docker compose version >/dev/null 2>&1; then
  _lib="$(mktemp)"
  mapfile -t _curl_auth < <(curl_auth_args)
  if ! curl -fsSL "${_curl_auth[@]}" "${RAW_BASE}/scripts/lib-compose-v2.sh" -o "${_lib}"; then
    echo "Не удалось скачать вспомогательный файл Compose v2 (${RAW_BASE}/scripts/lib-compose-v2.sh)." >&2
    rm -f "${_lib}"
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${_lib}"
  rm -f "${_lib}"
  ensure_compose_v2 || exit 1
fi

remove_free_amnezia_web_panel() {
  if [[ "${SKIP_REMOVE_FREE:-}" == "1" ]]; then
    echo "→ SKIP_REMOVE_FREE=1 — FREE-панель не удаляю."
    return 0
  fi
  echo "→ Удаляю FREE-панель Amnezia Web (освобождаю порт 8080 при необходимости)..."
  local c
  for c in amnezia-admin amnezia-web-landing; do
    docker rm -f "${c}" 2>/dev/null || true
  done
  docker rmi -f amnezia-admin:latest 2>/dev/null || true
  docker rmi -f amnezia-web-landing:latest 2>/dev/null || true
  rm -rf /opt/amnezia-admin 2>/dev/null || true
  echo "→ FREE-панель снята (контейнеры WireGuard/AmneziaWG не трогались)."
}

remove_free_amnezia_web_panel

echo "→ Получаю актуальный тег образа..."
mapfile -t _curl_auth < <(curl_auth_args)
IMAGE_TAG="$(trim "$(curl -fsSL "${_curl_auth[@]}" "${RAW_BASE}/PRO_IMAGE_TAG")")"
if [[ -z "${IMAGE_TAG}" ]]; then
  echo "Не удалось прочитать PRO_IMAGE_TAG с GitHub."
  exit 1
fi

if [[ ! -d "${INSTALL_ROOT}/.git" ]]; then
  need_cmd git
  mkdir -p "$(dirname "${INSTALL_ROOT}")"
  rm -rf "${INSTALL_ROOT}"
  echo "→ Клонирую ${DEPLOY_REPO} → ${INSTALL_ROOT}"
  git clone --depth 1 --branch main "${DEPLOY_REPO}" "${INSTALL_ROOT}"
else
  echo "→ Обновляю ${INSTALL_ROOT}"
  git -C "${INSTALL_ROOT}" fetch --depth 1 origin main
  git -C "${INSTALL_ROOT}" reset --hard "origin/main"
fi

echo ""
echo "Введите ключ доступа к образу (GitHub PAT с правом read:packages)."
echo "Ввод скрыт — символы не отображаются."
if [[ -r /dev/tty ]]; then
  IFS= read -rs GHCR_KEY < /dev/tty || true
else
  echo "Нет доступа к /dev/tty. Скачайте скрипт и запустите файлом."
  exit 1
fi
echo ""

GHCR_KEY="$(trim "${GHCR_KEY}")"
if [[ -z "${GHCR_KEY}" ]]; then
  echo "Ключ пустой — выход."
  exit 1
fi

tcp_port_in_use() {
  local port="$1"
  command -v ss >/dev/null 2>&1 || return 1
  ss -tln 2>/dev/null | awk -v pt="$port" '$4 ~ ":"pt"$" {found=1} END{exit !found}'
}

pick_host_port() {
  if [[ -n "${HOST_PORT:-}" ]]; then
    printf '%s' "${HOST_PORT}"
    return
  fi
  local want="8080"
  if ! tcp_port_in_use "${want}"; then
    printf '%s' "${want}"
    return
  fi
  local alt="8081"
  echo "⚠ Порт ${want} занят. Введите свободный порт [${alt}]:" >&2
  IFS= read -r line < /dev/tty || true
  line="$(trim "${line}")"
  [[ -z "${line}" ]] && line="${alt}"
  while tcp_port_in_use "${line}"; do
    echo "⚠ Порт ${line} тоже занят. Укажите другой:" >&2
    IFS= read -r line < /dev/tty || true
    line="$(trim "${line}")"
    [[ -z "${line}" ]] && exit 1
  done
  printf '%s' "${line}"
}

pick_awg_container_name() {
  if [[ -n "${AWG_CONTAINER:-}" ]]; then
    printf '%s' "${AWG_CONTAINER}"
    return
  fi
  if docker inspect amnezia-awg >/dev/null 2>&1; then
    printf '%s' 'amnezia-awg'
    return
  fi
  if docker inspect amnezia-awg2 >/dev/null 2>&1; then
    printf '%s' 'amnezia-awg2'
    return
  fi
  printf '%s' 'amnezia-awg2'
}

SELECTED_HOST_PORT="$(pick_host_port)"
SELECTED_AWG="$(pick_awg_container_name)"

umask 077
{
  printf 'GHCR_IMAGE=%q\n' "${DEFAULT_GHCR_IMAGE}"
  printf 'IMAGE_TAG=%q\n' "${IMAGE_TAG}"
  printf 'GHCR_USERNAME=%q\n' "${DEFAULT_GHCR_USERNAME}"
  printf 'GHCR_TOKEN=%q\n' "${GHCR_KEY}"
  printf 'HOST_PORT=%q\n' "${SELECTED_HOST_PORT}"
  printf 'CONTAINER_NAME=%q\n' "${CONTAINER_NAME:-amnezia-admin-pro}"
  printf 'AWG_CONTAINER=%q\n' "${SELECTED_AWG}"
  if [[ -n "${ADMIN_PASSWORD:-}" ]]; then
    printf 'ADMIN_PASSWORD=%q\n' "${ADMIN_PASSWORD}"
  fi
} >"${INSTALL_ROOT}/.env"

echo "→ Запуск установки из ${INSTALL_ROOT}"
exec bash "${INSTALL_ROOT}/scripts/install.sh"
