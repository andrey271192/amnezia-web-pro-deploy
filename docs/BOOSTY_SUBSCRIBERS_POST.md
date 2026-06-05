# Amnezia Web PRO — закрытый доступ для подписчиков

Amnezia Web PRO теперь в закрытом доступе. Установка и обновления идут через приватный GitHub-доступ для подписчиков.

Отдельно выражаю большую благодарность моим 6 подписчикам на Boosty. Ваша поддержка уже даёт мотивацию дальше дорабатывать проекты, учитывать пожелания людей, убирать баги и исправлять ошибки в работе. Благодаря вам такие инструменты выходят доступными для всех.

## Что это

Веб-панель для управления VPN-инфраструктурой на VPS:

- серверы через SSH;
- AmneziaWG 2.0, AmneziaWG, AWG Legacy, WireGuard, Xray, Telemt;
- клиенты, пользователи, роли, лимиты, QR-коды и конфиги;
- WARP, AmneziaDNS, AdGuard Home, SOCKS5;
- обновления из GitHub: стабильный канал, beta, выбор версии, откат.

## Доступ

Для установки нужен `GITHUB_TOKEN` с доступом к private repo. Токен нельзя публиковать в чатах, комментариях и скриншотах.

Если токен утёк, его нужно отозвать и выдать новый.

## Установка

VPS: Debian/Ubuntu, root-доступ.

```bash
export GITHUB_TOKEN='ТОКЕН_ИЗ_BOOSTY'
export ADMIN_PASSWORD='СЛОЖНЫЙ_ПАРОЛЬ'

curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh \
  | sudo -E bash
```

Другой порт панели:

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
- пароль: значение `ADMIN_PASSWORD`.

## Обновления и откат

В панели:

`Настройки → О программе и обновления → Проверить обновления`

Доступно:

- стабильные релизы;
- beta-версии;
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

## Если ошибка

`403 Forbidden` или `404 Not Found`:

- токен не передан;
- токен без доступа к private repo;
- токен отозван;
- доступ закончился.

`docker login succeeded`, но `pull ghcr.io/...` падает:

- это старый GHCR-сценарий;
- обычная установка теперь идёт из private GitHub source;
- GHCR для обычной установки не нужен.

`WARNING! Your credentials are stored unencrypted`:

- это предупреждение Docker;
- это не причина ошибки установки.

## Контакты

- Boosty: https://boosty.to/andrey27
- Telegram: @PCAdministration
- GitHub: https://github.com/andrey271192
