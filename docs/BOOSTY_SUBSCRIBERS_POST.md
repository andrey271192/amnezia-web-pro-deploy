# Шаблон закрытого поста Boosty (только для подписчиков)

## Поддержка проекта

---

- ⭐ **GitHub:** [andrey271192/amnezia-web-pro-deploy](https://github.com/andrey271192/amnezia-web-pro-deploy)
- 💖 **Boosty:** [boosty.to/andrey27/donate](https://boosty.to/andrey27/donate)
- 💳 **Ozon Bank (СБП):** [ссылка](https://finance.ozon.ru/apps/sbp/ozonbankpay/019dc200-2a5d-7931-a619-782d285f6798)
- ✉️ **Telegram:** [@lot_andrey](https://t.me/lot_andrey)

Скопируйте в Boosty и подставьте **один** секрет — ключ ниже.

---

## Amnezia Admin — Pro (Docker)

Спасибо за поддержку. Исходный код Pro не распространяется — доступ только к приватному образу на GitHub Container Registry.

### Установка одной командой

На VPS установите **Docker Engine** (`docker.io` / пакеты Docker CE) и утилиты **`curl`**, **`git`**, затем выполните **от root**:

```bash
sudo apt-get update && sudo apt-get install -y curl git docker.io
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo bash
```

Нужна именно команда **`docker compose`** (Compose v2). Если пакет **`docker-compose-plugin`** недоступен в ваших репозиториях APT, **обновлённый `quick-install.sh` сам ставит официальный плагин** с GitHub в `/usr/local/lib/docker/cli-plugins/` (можно отключить: см. файл `scripts/lib-compose-v2.sh` в репозитории установки). Старый пакет **`docker-compose`** 1.x из Ubuntu **не использовать** — на новых образах будет ошибка **ContainerConfig**.

Установщик **снимает FREE-панель** (типовой `amnezia_web`: контейнеры `amnezia-admin`, лендинг, образы и `/opt/amnezia-admin`). **Контейнер AmneziaWG/VPN не удаляется.** Затем ставится PRO и запрашивается ключ ниже.

Если FREE оставить нельзя по ошибке (редко): `SKIP_REMOVE_FREE=1 curl … | sudo -E bash`.

Если после вставки ключа появляются ошибки — альтернатива (тот же установщик):

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh -o /tmp/amnezia-quick-install.sh
sudo bash /tmp/amnezia-quick-install.sh
```

**Порт 8080 занят не FREE-панелью:** скрипт сам предложит другой порт, либо явно:

```bash
HOST_PORT=8081 curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo -E bash
```

### Ваш ключ (Personal Access Token для GHCR)

```
REPLACE_ME_PASTE_TOKEN_HERE
```

- Логин GitHub для registry уже зашит в установщик (`andrey271192`).
- Актуальный тег образа скрипт подтягивает сам из репозитория установки (`PRO_IMAGE_TAG`).

⚠️ Не публикуйте ключ в открытых чатах и скриншотах. Не отправляйте его третьим лицам.

### После установки

Панель: `http://ВАШ_IP:8080` (порт при необходимости задаётся переменной `HOST_PORT` до запуска quick-install или правкой `/opt/amnezia-web-pro-deploy/.env`).

Файлы установки: `/opt/amnezia-web-pro-deploy`

### Обновление

```bash
sudo bash /opt/amnezia-web-pro-deploy/scripts/update.sh
```

Тег образа подтягивается из публичного файла `PRO_IMAGE_TAG` при следующем запуске quick-install; для **update.sh** при новом релизе при необходимости обновите строку `IMAGE_TAG` в `/opt/amnezia-web-pro-deploy/.env` (или заново выполните `quick-install.sh` — он перезапишет `.env` и запросит ключ снова).

### Если подписка закончилась

Доступ к закрытому посту пропадает; выданный ключ можно отозвать на стороне GitHub — новые установки и pull образа станут невозможны без нового ключа.

---

**Поддержка:** напишите автору в личные сообщения на Boosty.
