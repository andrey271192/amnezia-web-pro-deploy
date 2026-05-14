# Amnezia Admin Pro — установка (Docker / GHCR)

Публичный репозиторий **только с инструкциями и compose**. Сам образ приложения — **приватный** на GitHub Container Registry; учётные данные для `docker pull` выдаются **активным подписчикам** (например, в закрытом посте на Boosty).

## Требования

- VPS с **Docker** и **Docker Compose v2** — команда **`docker compose`** (плагин `docker-compose-plugin`).  
  **Не подходит** старый **`docker-compose`** 1.x из Ubuntu — на новых образах будет ошибка **`ContainerConfig` / KeyError**.
- Установка плагина: `sudo apt-get update && sudo apt-get install -y docker-compose-plugin`
- Также нужны **curl** и при первой установке — **git**
- Активная подписка и **ключ** (GitHub PAT с `read:packages`), см. закрытый пост Boosty

## Одна команда — FREE → PRO (спросит только ключ)

На VPS **от root**:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo bash
```

Скрипт **перед установкой PRO**:

1. **Убирает FREE-панель** из типового `install.sh` (**amnezia_web**): контейнеры `amnezia-admin`, `amnezia-web-landing`, локальные образы `amnezia-admin:latest` / `amnezia-web-landing:latest`, каталог сборки **`/opt/amnezia-admin`**.  
2. **Не трогает** контейнеры VPN (**AmneziaWG / AWG**): **`amnezia-awg`**, **`amnezia-awg2`** и т.п.  
3. Подставляет **`AWG_CONTAINER`** автоматически, если на сервере уже есть `amnezia-awg` или `amnezia-awg2`.  
4. Клонирует/обновляет **`/opt/amnezia-web-pro-deploy`**, тянет тег из [`PRO_IMAGE_TAG`](PRO_IMAGE_TAG), запрашивает **ключ PAT** (ввод с **`/dev/tty`**).

Отключить снос FREE (редко нужно): `SKIP_REMOVE_FREE=1 curl … | sudo -E bash`.

Если **нет интерактива** на stdin:

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh -o /tmp/amnezia-quick-install.sh
sudo bash /tmp/amnezia-quick-install.sh
```

**Порт:** если после удаления FREE **8080** всё ещё занят — скрипт предложит другой или задайте `HOST_PORT=8081 curl … | sudo -E bash`.

## Частые проблемы после установки

### `Bind for 0.0.0.0:8080 failed: port is already allocated`

На **8080** уже слушает другой процесс или контейнер (не только снятая FREE-панель). Посмотреть занятость: `ss -tlnp | grep ':8080'`. Обход: переустановка с **`HOST_PORT=8081`** (или свободный порт):

```bash
HOST_PORT=8081 curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo -E bash
```

### `KeyError: 'ContainerConfig'` и в трассировке указан **`docker-compose` 1.29.x** (`/usr/lib/python3/...`)

Старый **Docker Compose v1** из пакета `docker-compose` **непонимает** образы из GHCR с современным OCI-манифестом без поля **`ContainerConfig`**. Нужна **Compose v2** — команда **`docker compose`** (пакет-плагин).

```bash
sudo apt-get update
sudo apt-get install -y docker-compose-plugin
docker compose version
```

Затем обновите файлы установки (**на ветке `main` уже запрещён fallback на 1.x**):

```bash
sudo git -C /opt/amnezia-web-pro-deploy fetch origin main
sudo git -C /opt/amnezia-web-pro-deploy reset --hard origin/main
```

Если после неудачного `up` образовался полубитый контейнер:

```bash
sudo docker rm -f amnezia-admin-pro 2>/dev/null || true
sudo bash /opt/amnezia-web-pro-deploy/scripts/install.sh
```

Если файл **`.env` удалён или пуст**, снова запустите **`quick-install.sh`** — он заново попросит PAT.

## Ручной способ (git + .env)

```bash
git clone https://github.com/andrey271192/amnezia-web-pro-deploy.git
cd amnezia-web-pro-deploy
cp .env.example .env
# заполните GHCR_* из закрытого поста Boosty
sudo bash scripts/install.sh
```

## Публикация на GitHub (для автора)

1. Создайте на GitHub новый репозиторий **`amnezia-web-pro-deploy`**, тип **Public** (без автогенерации README, если заливаете уже готовые файлы).
2. В каталоге с этим проектом:

```bash
cd amnezia-web-pro-deploy
git init
git add -A
git commit -m "Initial public deploy bundle"
git branch -M main
git remote add origin https://github.com/andrey271192/amnezia-web-pro-deploy.git
git push -u origin main
```

Если GitHub при создании репозитория уже добавил коммит — сделайте `git pull origin main --allow-unrelated-histories`, затем push.

## Обновление

После объявления нового тега образа обновите `IMAGE_TAG` в `.env` и выполните:

```bash
sudo bash scripts/update.sh
```

## Шаблон поста для Boosty

См. [docs/BOOSTY_SUBSCRIBERS_POST.md](docs/BOOSTY_SUBSCRIBERS_POST.md).

## Безопасность

- Файл `.env` с токеном не должен попадать в issue, чаты и скриншоты.
- При утечке токена автор перевыпускает его в GitHub; подписчикам выдаётся новый токен в обновлённом посте.
