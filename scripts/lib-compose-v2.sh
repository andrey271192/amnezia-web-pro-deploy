#!/usr/bin/env bash
# Функции для проверки и установки Docker Compose v2 («docker compose»).
# Файл предназначен для source из quick-install (через curl) и из install/update.

compose_plugin_download_name_for_arch() {
  case "$(uname -m)" in
    x86_64 | amd64)
      printf '%s' docker-compose-linux-x86_64
      ;;
    aarch64 | arm64)
      printf '%s' docker-compose-linux-aarch64
      ;;
    armv7l)
      printf '%s' docker-compose-linux-armv7
      ;;
    *)
      printf '%s' ''
      ;;
  esac
}

compose_v2_ok() {
  docker compose version >/dev/null 2>&1
}

print_compose_v2_help_text() {
  cat <<'EOF'

Нужен Docker Compose v2 — команда «docker compose».

• Быстро (если хотите ставить только плагин, без нашего автозагрузчика):

  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  ARCH=$(uname -m)
  case "$ARCH" in x86_64|amd64) N=docker-compose-linux-x86_64 ;; aarch64|arm64) N=docker-compose-linux-aarch64 ;; *) echo "Архитектура не поддерживается: $ARCH"; exit 1 ;; esac
  sudo curl -fsSL "https://github.com/docker/compose/releases/download/v2.36.0/${N}" -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  docker compose version

• Если удобнее через репозиторий Docker CE (Ubuntu):

  см. https://docs.docker.com/engine/install/ubuntu/

  После добавления repo: sudo apt-get update && sudo apt-get install -y docker-compose-plugin

• Принудительно отключить авто‑скачивание плагина из quick-install/install:

  DISABLE_STANDALONE_COMPOSE_DOWNLOAD=1

• Версия релиза GitHub задаётся переменной COMPOSE_CLI_VERSION (по умолчанию v2.36.0).
EOF
}

try_apt_install_docker_compose_plugin() {
  command -v apt-get >/dev/null 2>&1 || return 1
  if ! apt-cache show docker-compose-plugin >/dev/null 2>&1; then
    return 1
  fi
  local cand=""
  cand="$(apt-cache policy docker-compose-plugin 2>/dev/null | awk '/^  Candidate:/ {print $2; exit}')"
  if [[ -z "${cand}" || "${cand}" == "(none)" ]]; then
    return 1
  fi

  echo "→ APT: устанавливаю docker-compose-plugin..." >&2
  DEBIAN_FRONTEND=noninteractive apt-get update -qq ||
    DEBIAN_FRONTEND=noninteractive apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose-plugin
}

install_compose_v2_cli_plugin_standalone() {
  local name version url plugin_dir tmp target

  name="$(compose_plugin_download_name_for_arch)"
  if [[ -z "${name}" ]]; then
    echo "Ошибка: архитектура $(uname -m) не поддерживается авто‑установкой Compose v2." >&2
    return 1
  fi

  version="${COMPOSE_CLI_VERSION:-v2.36.0}"
  url="https://github.com/docker/compose/releases/download/${version}/${name}"
  plugin_dir="${COMPOSE_CLI_PLUGIN_DIR:-/usr/local/lib/docker/cli-plugins}"
  target="${plugin_dir}/docker-compose"
  tmp="${target}.tmp.$$"

  echo "→ Скачиваю Docker Compose ${version} → ${target}" >&2
  mkdir -p "${plugin_dir}"
  curl -fsSL "${url}" -o "${tmp}"
  chmod +x "${tmp}"
  mv -f "${tmp}" "${target}"
}

# Требует root для APT/записи в /usr/local (у standalone).
ensure_compose_v2() {
  if compose_v2_ok; then
    return 0
  fi

  echo "Не найдена команда «docker compose» (Compose v2)." >&2
  echo "Старый «docker-compose» 1.x из apt здесь не подходит (ошибка ContainerConfig на новых образах)." >&2

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    print_compose_v2_help_text >&2
    return 1
  fi

  if try_apt_install_docker_compose_plugin && compose_v2_ok; then
    docker compose version | head -n1 >&2
    return 0
  fi

  if [[ "${DISABLE_STANDALONE_COMPOSE_DOWNLOAD:-}" == "1" ]]; then
    print_compose_v2_help_text >&2
    return 1
  fi

  if ! install_compose_v2_cli_plugin_standalone || ! compose_v2_ok; then
    print_compose_v2_help_text >&2
    return 1
  fi

  docker compose version | head -n1 >&2
}
