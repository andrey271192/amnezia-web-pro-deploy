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
# При «curl … | sudo bash» stdin — это поток скрипта, а не клавиатура.
# Читаем ключ с настоящего терминала; иначе read получает EOF и ломает .env.
if [[ -r /dev/tty ]]; then
  echo "Введите ключ доступа к образу (GitHub PAT с правом read:packages)."
  echo "Ввод скрыт — символы не отображаются."
  IFS= read -rs GHCR_KEY < /dev/tty || true
else
  echo "Нет доступа к /dev/tty (интерактивный ввод недоступен)."
  echo "Скачайте скрипт и запустите файлом:"
  echo "  curl -fsSL ${RAW_BASE}/quick-install.sh -o /tmp/amnezia-quick-install.sh"
  echo "  sudo bash /tmp/amnezia-quick-install.sh"
  exit 1
fi
echo ""

GHCR_KEY="$(trim "${GHCR_KEY}")"
if [[ -z "${GHCR_KEY}" ]]; then
  echo "Ключ пустой — выход."
  exit 1
fi

umask 077
# %q экранирует $ и прочее — безопасно для «source .env» в install.sh
{
  printf 'GHCR_IMAGE=%q\n' "${DEFAULT_GHCR_IMAGE}"
  printf 'IMAGE_TAG=%q\n' "${IMAGE_TAG}"
  printf 'GHCR_USERNAME=%q\n' "${DEFAULT_GHCR_USERNAME}"
  printf 'GHCR_TOKEN=%q\n' "${GHCR_KEY}"
  printf 'HOST_PORT=%q\n' "${HOST_PORT:-8080}"
  printf 'CONTAINER_NAME=%q\n' "${CONTAINER_NAME:-amnezia-admin-pro}"
  printf 'AWG_CONTAINER=%q\n' "${AWG_CONTAINER:-amnezia-awg2}"
} >"${INSTALL_ROOT}/.env"

echo "→ Запуск установки из ${INSTALL_ROOT}"
exec bash "${INSTALL_ROOT}/scripts/install.sh"
