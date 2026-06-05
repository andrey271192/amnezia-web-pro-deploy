# Amnezia Web PRO — доступ для подписчиков

Отдельно выражаю большую благодарность моим 6 подписчикам на Boosty. Ваша поддержка уже даёт мотивацию дальше дорабатывать проекты, учитывать пожелания людей, убирать баги и исправлять ошибки в работе. Благодаря вам такие инструменты выходят доступными для всех.

Amnezia Web PRO теперь закрыт. Доступ к установке и обновлениям выдаётся подписчикам через приватный GitHub-доступ.

## Что внутри

- веб-панель для VPN-серверов на VPS;
- AmneziaWG 2.0, AmneziaWG, AWG Legacy, WireGuard, Xray, Telemt;
- клиенты, пользователи, роли, лимиты, QR и конфиги;
- Cloudflare WARP, AmneziaDNS, AdGuard Home, SOCKS5;
- обновления из GitHub: release, beta, выбор версии и rollback.

## Важно

Токен нельзя публиковать в чатах, комментариях и скриншотах. Если токен утёк, его нужно отозвать и выдать новый.

## Установка

На свежем VPS с Debian/Ubuntu:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export ADMIN_PASSWORD='СЛОЖНЫЙ_ПАРОЛЬ'

curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh \
  | sudo -E bash
```

Если нужен другой порт панели:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export ADMIN_PASSWORD='СЛОЖНЫЙ_ПАРОЛЬ'
export NGINX_HTTP_PORT=25050

curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh \
  | sudo -E bash
```

После установки:

- панель: `http://IP_СЕРВЕРА:25050/panel/`;
- логин: `admin`;
- пароль: тот, который указан в `ADMIN_PASSWORD`.

## Обновления

В панели:

`Настройки → О программе и обновления → Проверить обновления`

Доступно:

- стабильный канал release;
- beta-канал;
- установка выбранной версии;
- откат на старый tag.

Ручное обновление:

```bash
cd /opt/amnezia-web-pro
git pull
docker compose build
docker compose up -d
```

## Удаление

Остановить панель, данные оставить:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'

curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
  | sudo -E bash
```

Полная очистка с данными и каталогом:

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'

curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
  | sudo REMOVE_DATA=1 REMOVE_DIR=1 bash
```

## Частые проблемы

`403 Forbidden` или `404 Not Found` при скачивании:

- токен не передан в команду;
- токен без доступа к private repo;
- токен отозван;
- подписка/доступ закончились.

`docker login succeeded`, но `pull ghcr.io/...` падает:

- это старый GHCR-сценарий;
- новая установка идёт из private GitHub source;
- GHCR больше не нужен для обычной установки.

`WARNING! Your credentials are stored unencrypted`:

- это предупреждение Docker;
- это не причина ошибки установки.

## Контакты

- Boosty: https://boosty.to/andrey27
- Telegram: @PCAdministration
- GitHub: https://github.com/andrey271192
