# Amnezia Web PRO — установка

Публичный установщик для **Amnezia Web PRO**. По умолчанию ставит панель из открытого GitHub repo:

- source: [`andrey271192/amnezia_web-PRO_test`](https://github.com/andrey271192/amnezia_web-PRO_test)
- текущий релиз: `v1.5.2`
- old GHCR image больше не используется по умолчанию, чтобы у пользователей не было `403 Forbidden`.

## Быстрая установка

На VPS от root:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo bash
```

То же самое с явным первым паролем admin:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh \
  | sudo ADMIN_PASSWORD='СЛОЖНЫЙ_ПАРОЛЬ' bash
```

`quick-install.sh` скачает и запустит рабочий установщик:

```bash
https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/install.sh
```

## Почему больше не GHCR

Старый сценарий тянул private image:

```text
ghcr.io/andrey271192/amnezia-admin-pro:v1.0.0
```

Если у GitHub PAT нет доступа к package или package закрыт, Docker показывает:

```text
unexpected status ... 403 Forbidden
```

Это не ошибка VPS и не ошибка Docker. Это отказ GitHub Container Registry. Чтобы не ловить эту ошибку у подписчиков, обычная установка теперь идёт из GitHub source.

Предупреждение Docker:

```text
WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'
```

не является причиной ошибки. Это только предупреждение Docker.

## Legacy GHCR mode

Оставлен только для ручного использования, если у вас реально есть доступ к package:

```bash
USE_GHCR=1 curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo -E bash
```

или:

```bash
USE_GHCR=1 sudo -E bash scripts/install.sh
```

Нужны:

- GitHub PAT с `read:packages`;
- доступ к package `ghcr.io/andrey271192/amnezia-admin-pro`;
- существующий tag из `PRO_IMAGE_TAG`.

## Удаление

Обычная остановка панели:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh | sudo bash
```

Полная очистка с данными:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia_web-PRO_test/main/uninstall.sh \
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
