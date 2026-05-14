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

# Порт панели на хосте (8080 часто занят старой установкой amnezia-admin и т.п.)
tcp_port_in_use() {
  local port="$1"
  command -v ss >/dev/null 2>&1 || return 1
  ss -tln 2>/dev/null | awk -v pt="$port" '$4 ~ ":"pt"$" {found=1} END{exit !found}'
}

pick_host_port() {
  # Явный HOST_PORT=… (часто с sudo -E) — не переопределяем.
  if [[ -n "${HOST_PORT:-}" ]]; then
    printf '%s' "${HOST_PORT}"
    return
  fi
  local want="8080"
  if ! tcp_port_in_use "${want}"; then
    printf '%s' "${want}"
    return
  fi
  echo "⚠ Порт ${want} уже занят на этом сервере (часто это старая панель или другой контейнер)." >&2
  local alt="8081"
  if [[ -r /dev/tty ]]; then
    echo "Введите свободный порт для веб-панели [${alt}]:" >&2
    IFS= read -r line < /dev/tty || true
    line="$(trim "${line}")"
    [[ -z "${line}" ]] && line="${alt}"
    while tcp_port_in_use "${line}"; do
      echo "⚠ Порт ${line} тоже занят. Укажите другой:" >&2
      IFS= read -r line < /dev/tty || true
      line="$(trim "${line}")"
      [[ -z "${line}" ]] && {
        echo "Порт не указан — выход." >&2
        exit 1
      }
    done
    printf '%s' "${line}"
    return
  fi
  echo "Нет /dev/tty — пробую ${alt}. При необходимости задайте HOST_PORT=… и повторите запуск." >&2
  if tcp_port_in_use "${alt}"; then
    echo "И ${alt} занят. Задайте явно: HOST_PORT=9080 curl … | sudo -E bash" >&2
    exit 1
  fi
  printf '%s' "${alt}"
}

SELECTED_HOST_PORT="$(pick_host_port)"

umask 077
# %q экранирует $ и прочее — безопасно для «source .env» в install.sh
{
  printf 'GHCR_IMAGE=%q\n' "${DEFAULT_GHCR_IMAGE}"
  printf 'IMAGE_TAG=%q\n' "${IMAGE_TAG}"
  printf 'GHCR_USERNAME=%q\n' "${DEFAULT_GHCR_USERNAME}"
  printf 'GHCR_TOKEN=%q\n' "${GHCR_KEY}"
  printf 'HOST_PORT=%q\n' "${SELECTED_HOST_PORT}"
  printf 'CONTAINER_NAME=%q\n' "${CONTAINER_NAME:-amnezia-admin-pro}"
  printf 'AWG_CONTAINER=%q\n' "${AWG_CONTAINER:-amnezia-awg2}"
} >"${INSTALL_ROOT}/.env"

echo "→ Запуск установки из ${INSTALL_ROOT}"
exec bash "${INSTALL_ROOT}/scripts/install.sh"
