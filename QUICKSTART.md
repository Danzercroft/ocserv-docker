# Быстрый старт OCServ Docker

## О проекте

Этот Docker образ использует **OCServ, собранный из исходного кода** версии 1.3.0 на базе Ubuntu 24.04 LTS.
Все возможности включены: PAM, RADIUS, GSSAPI, компрессия, seccomp.

Проект размещен на GitHub: https://github.com/Danzercroft/ocserv-docker

## ⚠️ Время сборки

**Первая сборка займет 10-20 минут** так как OCServ компилируется из исходного кода.
Последующие сборки будут быстрее благодаря Docker кешу.

## 1. Первоначальная настройка

```bash
# Копирование переменных окружения
cp .env.example .env

# Редактирование настроек (опционально)
nano .env

# Настройка скриптов
make setup
```

## 2. Создание пользователей

```bash
# Добавление пользователя интерактивно
./scripts/add_user.sh username

# Или через Makefile
make add-user USER=username
```

## 3. Запуск сервера

```bash
# Сборка и запуск
make build
make start

# Или одной командой
docker-compose up -d --build
```

## 4. Проверка статуса

```bash
# Статус сервера
make status

# Логи
make logs

# Подключенные пользователи
make users
```

## 5. Подключение клиентов

### Linux:
```bash
sudo openconnect -u username your.server.com:443
```

### Windows/macOS:
- Установить Cisco AnyConnect
- Сервер: `your.server.com:443`
- Использовать созданные логин/пароль

## 6. Управление пользователями

```bash
# Добавить пользователя
make add-user USER=newuser

# Удалить пользователя
make remove-user USER=olduser

# Список пользователей
cat config/passwd | cut -d: -f1
```

## 7. Мониторинг

```bash
# Мониторинг в реальном времени
make monitor

# Статистика
make stats
```

## 8. Обслуживание

```bash
# Перезапуск
make restart

# Остановка
make stop

# Полная очистка и пересборка
make reset

# Резервное копирование
make backup
```
