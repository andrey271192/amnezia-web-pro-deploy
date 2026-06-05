# Amnezia Web PRO Deploy

Приватный установщик **Amnezia Web PRO** на VPS. Доступ к репозиториям выдаётся подписчикам Boosty.

По умолчанию установка идёт из private source repo:

- source: `andrey271192/amnezia_web-PRO_test`;
- текущий релиз: `v1.5.2`;
- old GHCR image больше не используется по умолчанию;
- legacy GHCR mode оставлен только вручную через `USE_GHCR=1`.
- нужен `GITHUB_TOKEN` с доступом к private repo.

## Что делает установщик

- скачивает актуальный `install.sh` из `amnezia_web-PRO_test`;
- ставит Docker, если его нет;
- разворачивает панель в `/opt/amnezia-web-pro`;
- создаёт `.env`;
- собирает и запускает Docker Compose stack;
- поддерживает явный первый пароль admin через `ADMIN_PASSWORD`;
- не требует GHCR PAT для обычной установки;
- требует GitHub token для доступа к private source.

## Быстрая установка

На VPS от root:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo -E bash
```

То же самое с явным первым паролем admin:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export ADMIN_PASSWORD='СЛОЖНЫЙ_ПАРОЛЬ'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo -E bash
```

`quick-install.sh` скачает и запустит рабочий установщик:

```bash
https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh
```

Если `GITHUB_TOKEN` не передан, private GitHub вернёт `404` или `403`. Это нормально: repo закрыт.

## Почему больше не GHCR

Старый сценарий тянул private image:

```text
ghcr.io/andrey271192/amnezia-admin-pro:v1.0.0
```

Если у GitHub PAT нет доступа к package или package закрыт, Docker показывает:

```text
unexpected status ... 403 Forbidden
```

Это не ошибка VPS и не ошибка Docker. Это отказ GitHub Container Registry. Чтобы не ловить эту ошибку у подписчиков, обычная установка теперь идёт из private GitHub source.

Предупреждение Docker:

```text
WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'
```

не является причиной ошибки. Это только предупреждение Docker.

## Legacy GHCR mode

Оставлен только для ручного использования, если у вас реально есть доступ к package:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
USE_GHCR=1 curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo -E bash
```

или:

```bash
USE_GHCR=1 sudo -E bash scripts/install.sh
```

Нужны:

- GitHub PAT с `read:packages`;
- доступ к package `ghcr.io/andrey271192/amnezia-admin-pro`;
- существующий tag из `PRO_IMAGE_TAG`.

## Проблемы и решения

### `403 Forbidden` при `docker pull ghcr.io/...`

Причина: старый GHCR-сценарий пытается скачать private image, а у token нет доступа к package.

Решение: используйте обычную private source установку без GHCR:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo -E bash
```

### `Login Succeeded`, но pull всё равно падает

`docker login` проверяет только логин/token. Он не гарантирует доступ к конкретному package.

Решение: не используйте GHCR-режим. Если GHCR всё-таки нужен, проверьте:

- PAT имеет `read:packages`;
- GitHub account имеет доступ к package;
- package не private для этого пользователя;
- tag из `PRO_IMAGE_TAG` реально опубликован.

### `WARNING! Your credentials are stored unencrypted`

Это предупреждение Docker, не ошибка установки. Оно не вызывает `403 Forbidden`.

### `Docker daemon недоступен`

Docker установлен, но сервис не запущен.

```bash
sudo systemctl enable --now docker
docker info
```

### `docker compose` не найден

Обычный source installer сам ставит Docker Compose plugin. Если запускаете legacy GHCR mode вручную, обновите Docker/Compose:

```bash
sudo apt-get update
sudo apt-get install -y docker-compose-plugin
docker compose version
```

### Порт панели занят

Укажите другой порт при установке основного проекта:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export NGINX_HTTP_PORT=8081
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh \
  | sudo -E bash
```

### Не входит в панель после переустановки

Задайте новый пароль admin явно:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export ADMIN_PASSWORD='НОВЫЙ_ПАРОЛЬ'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh \
  | sudo -E bash
```

### Нужна полная переустановка

Удалите панель с данными и поставьте заново:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
  | sudo REMOVE_DATA=1 REMOVE_DIR=1 bash
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo -E bash
```

## Удаление

Обычная остановка панели:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
  | sudo -E bash
```

Полная очистка с данными:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
  | sudo REMOVE_DATA=1 REMOVE_DIR=1 bash
```

## Обновление

В панели: **Настройки → О программе и обновления → Проверить обновления**.

Доступно:

- release channel;
- beta channel;
- выбор версии;
- rollback на старый tag.

Ручное обновление source-установки:

```bash
cd /opt/amnezia-web-pro
git pull
docker compose build
docker compose up -d
```

## Поддержка проекта

- GitHub: [andrey271192/amnezia_web-PRO_test](https://github.com/andrey271192/amnezia_web-PRO_test)
- Boosty: [boosty.to/andrey27/donate](https://boosty.to/andrey27/donate)
- Telegram: [@lot_andrey](https://t.me/lot_andrey)
