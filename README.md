# Amnezia Admin Pro — установка (Docker / GHCR)

Публичный репозиторий **только с инструкциями и compose**. Сам образ приложения — **приватный** на GitHub Container Registry; учётные данные для `docker pull` выдаются **активным подписчикам** (например, в закрытом посте на Boosty).

## Требования

- VPS с **Docker** и **Docker Compose v2** (`docker compose`), **curl**, при первой установке — **git**
- Активная подписка и **ключ** (GitHub PAT с `read:packages`), см. закрытый пост Boosty

## Одна ссылка — установка (спросит только ключ)

Скопируйте и выполните на VPS **от root** (или через `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/amnezia-web-pro-deploy/main/quick-install.sh | sudo bash
```

Скрипт сам возьмёт актуальный тег образа из файла [`PRO_IMAGE_TAG`](PRO_IMAGE_TAG), склонирует этот репозиторий в `/opt/amnezia-web-pro-deploy` и попросит ввести **ключ** (персональный токен для `docker pull` с GHCR). Ввод скрыт.

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
