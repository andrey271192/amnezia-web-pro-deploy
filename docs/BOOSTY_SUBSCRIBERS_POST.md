# Шаблон закрытого поста Boosty (только для подписчиков)

Скопируйте в Boosty и замените плейсхолдеры.

---

## Amnezia Admin — Pro (Docker)

Спасибо за поддержку. Исходный код Pro не распространяется — доступ только к готовому образу в GitHub Container Registry.

### 1) Открытая инструкция и файлы

Репозиторий установки (публичный):  
https://github.com/andrey271192/amnezia-web-pro-deploy

На VPS (Ubuntu/Debian, установлен Docker):

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/andrey271192/amnezia-web-pro-deploy.git
cd amnezia-web-pro-deploy
cp .env.example .env
nano .env
```

### 2) Заполните `.env` значениями ниже

| Переменная | Значение для подписчиков |
|------------|--------------------------|
| `GHCR_IMAGE` | `ghcr.io/andrey271192/amnezia-admin-pro` |
| `IMAGE_TAG` | `v1.0.0` *(или актуальный тег из объявления)* |
| `GHCR_USERNAME` | **`REPLACE_ME_USERNAME`** |
| `GHCR_TOKEN` | **`REPLACE_ME_TOKEN`** |

⚠️ Не выкладывайте `.env` и токен в открытый доступ. Не коммитьте их в git.

### 3) Установка одной командой

```bash
sudo bash scripts/install.sh
```

Панель: `http://ВАШ_IP:8080` (порт меняется через `HOST_PORT` в `.env`).

### 4) Обновление до новой версии

В посте при новом релизе будет указан новый `IMAGE_TAG`. В `.env` замените `IMAGE_TAG`, затем:

```bash
cd amnezia-web-pro-deploy
sudo bash scripts/update.sh
```

### 5) Если подписка закончилась

Доступ к закрытым материалам Boosty пропадает; pull-токен может быть отозван при ротации — новые установки и обновления станут недоступны без активной подписки.

---

**Поддержка:** напишите автору в личные сообщения на Boosty (вопросы по установке и обновлению).
