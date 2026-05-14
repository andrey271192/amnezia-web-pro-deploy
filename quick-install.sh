#!/usr/bin/env bash
# Одна команда: curl … | sudo bash — спросит только ключ (PAT для ghcr.io).
set -euo pipefail

DEPLOY_REPO="${DEPLOY_REPO:-https://github.com/andrey271192/amnezia-web-pro-deploy.git}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main}"
INSTALL_ROOT="${INSTALL_ROOT:-/opt/amnezia-web-pro-deploy}"

DEFAULT_GHCR_IMAGE="${DEFAULT_GHCR_IMAGE:-ghcr.io/andrey271192/amnezia-admin-pro}"
DEFAULT_GHCR_USERNAME="${DEFAULT_GHCR_USERNAME:-andrey271192}"

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Запустите: curl -fsSL ${RAW_BASE}/quick-install.sh | sudo bash"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Нужна утилита: $1 (например: apt-get install -y $1)"
    exit 1
  }
}

trim() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

need_root
need_cmd curl
need_cmd docker

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon недоступен. Запустите Docker и повторите."
  exit 1
fi

echo "→ Получаю актуальный тег образа..."
IMAGE_TAG="$(trim "$(curl -fsSL "${RAW_BASE}/PRO_IMAGE_TAG")")"
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
read -rs GHCR_KEY
echo ""

GHCR_KEY="$(trim "${GHCR_KEY}")"
if [[ -z "${GHCR_KEY}" ]]; then
  echo "Ключ пустой — выход."
  exit 1
fi

umask 077
cat >"${INSTALL_ROOT}/.env" <<EOF
GHCR_IMAGE=${DEFAULT_GHCR_IMAGE}
IMAGE_TAG=${IMAGE_TAG}
GHCR_USERNAME=${DEFAULT_GHCR_USERNAME}
GHCR_TOKEN=${GHCR_KEY}
HOST_PORT=${HOST_PORT:-8080}
CONTAINER_NAME=${CONTAINER_NAME:-amnezia-admin-pro}
AWG_CONTAINER=${AWG_CONTAINER:-amnezia-awg2}
EOF

echo "→ Запуск установки из ${INSTALL_ROOT}"
exec bash "${INSTALL_ROOT}/scripts/install.sh"
