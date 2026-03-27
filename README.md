# OCServ Docker Project

Контейнер OCServ VPN сервера на базе Alpine Linux с полной поддержкой настройки через переменные окружения.

## Возможности

- 🔧 **Минимальная конфигурация** - Статический конфиг и secrets
- 🔒 **Безопасное хранение секретов** - Сертификаты и файл паролей только как Docker secrets
- 🐧 **Alpine Linux** - Минимальный размер образа
- 📦 **Компиляция из исходников** - OCServ собирается из master ветки GitLab
- 🔗 **Поддержка AnyConnect** - Совместимость с Cisco AnyConnect клиентами
- 🌐 **Гибкая настройка сети** - Настройка IP диапазонов, DNS, маршрутизации

## Быстрый старт

1. **Клонируйте проект:**
```bash
git clone https://github.com/Danzercroft/ocserv-docker.git
cd ocserv-docker
```

2. **Подготовьте SSL сертификаты:**
```bash
# Поместите ваши сертификаты в директорию certs/
cp your-server.crt certs/server.crt
cp your-server.key certs/server.key

# Или создайте тестовые самоподписанные сертификаты
cd certs && openssl genrsa -out server.key 3072
openssl req -new -key server.key -out server.csr -subj "/CN=vpn.example.com"
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt
rm server.csr && cd ..
```

3. **Настройте переменные окружения:**
```bash
cp .env.example .env
# Отредактируйте .env файл под ваши нужды
```

4. **Запустите контейнер:**
```bash
docker-compose up -d
```

## Docker Compose Configs и Secrets

Проект использует Docker Compose configs и secrets для безопасного управления конфигурационными файлами и секретными данными:

### Configs
- **ocserv_config**: Конфигурационный файл OCServ (`./config/ocserv.conf`)
  - Монтируется в контейнер как `/etc/ocserv/ocserv.conf`
  - Права доступа: 0644
  - Содержит статическую конфигурацию с разумными значениями по умолчанию

### Secrets
- **ocserv_passwd**: Файл паролей пользователей (`./config/passwd`)
  - В контейнере как secret: `/run/secrets/ocserv_passwd` 
  - Права доступа: 0600

- **server_cert**: SSL сертификат сервера (`./certs/server.crt`)
  - Secret: `/run/secrets/server_cert`
  - Права доступа: 0644

- **server_key**: Приватный ключ сервера (`./certs/server.key`)
  - Secret: `/run/secrets/server_key`
  - Права доступа: 0600

### Преимущества такого подхода
- **Безопасность**: Секретные данные не копируются в образ Docker
- **Простота**: Конфигурация использует разумные значения по умолчанию
- **Гибкость**: Основные параметры настраиваются через переменные окружения
- **Изоляция**: Configs и secrets обрабатываются в соответствии с их назначением
- **Права доступа**: Автоматическая установка корректных прав для файлов

### Использование в Docker Swarm

В режиме Swarm secrets автоматически доступны в каталоге `/run/secrets/*` с именами, совпадающими с названием секрета:

| Secret | Путь в контейнере | Использование |
|--------|-------------------|--------------|
| `ocserv_passwd` | `/run/secrets/ocserv_passwd` | Файл пользователей (auth) |
| `server_cert` | `/run/secrets/server_cert` | Сертификат сервера |
| `server_key` | `/run/secrets/server_key` | Приватный ключ |

Файл `ocserv.conf` обновлен для использования этих путей.

## ENV переменные

Базовая конфигурация статична. Доступны следующие переменные:

### Metrics (опционально)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `ENABLE_METRICS` | `true` | Включить/отключить экспорт метрик |
| `METRICS_PORT` | `8000` | Порт экспортера |
| `METRICS_INTERVAL` | `30` | Интервал опроса ocserv (сек) |

### Пути к сертификатам (опционально)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `SERVER_CERT_PATH` | `/run/secrets/server_cert` | Путь к сертификату сервера |
| `SERVER_KEY_PATH` | `/run/secrets/server_key` | Путь к приватному ключу |
| `PASSWD_PATH` | `/run/secrets/ocserv_passwd` | Путь к файлу паролей |

### Сеть и Отладка (опционально)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `OCSERV_IP_POOL` | `10.10.10.0/24` | IP Пул для клиентов, влияет на NAT iptables |
| `OCSERV_DEBUG` | `false` | Включить расширенное логирование ocserv |
| `OCSERV_DEBUG_LEVEL` | `9999` | Уровень отладки (если включен DEBUG) |

### Дополнительно

Переменная `ENABLE_LOGS` удалена. Используйте стандартный вывод контейнера и системы логирования Docker.

## Встроенные значения по умолчанию

Следующие параметры настроены в статическом конфигурационном файле и не требуют переменных окружения:

- **Клиенты**: max-clients = 128, max-same-clients = 10
- **Сессии**: keepalive = 30, dpd = 60, mobile-dpd = 300
- **Аутентификация**: auth-timeout = 240, cookie-timeout = 300
- **Безопасность**: ban-score = 80, ban-reset-time = 300, min-reauth-time = 300
- **DNS**: dns = 8.8.8.8, dns = 1.1.1.1, tunnel-all-dns = true
- **IPv6**: ipv6-network = fda9:4efe:7e3b:03ea::/48, ipv6-subnet-prefix = 64
- **Прочее**: compression = true, cisco-client-compat = true, log-level = 1

## Управление пользователями

Пользователи задаются статически в файле `config/passwd` (монтируется как secret `ocserv_passwd`). Формат строк:
```
username:password_hash
```

Генерация хеша (SHA512, рекомендовано):
```bash
openssl passwd -6 "ваш_пароль"
```

После изменения файла `config/passwd` пересоздайте secret (для Docker Swarm) и перезапустите сервис:
```bash
docker secret rm ocserv_passwd 2>/dev/null || true
docker secret create ocserv_passwd config/passwd
docker service update --force <service_name>
```

## Логи и мониторинг

Проект поддерживает экспорт метрик через встроенный ocserv-exporter.

### Просмотр логов
```bash
# Просмотр всех логов
docker-compose logs -f ocserv

# Только логи доступа
docker-compose logs ocserv 2>&1 | grep '\[ACCESS\]'

# Только ошибки
docker-compose logs ocserv 2>&1 | grep '\[ERROR\]'

# Состояние контейнера
docker-compose ps
```

### Метрики Prometheus

Доступ к метрикам:
```bash
# Просмотр метрик
curl http://localhost:8000/metrics

# Проверка статуса экспортера
docker-compose exec ocserv pgrep ocserv-exporter
```

Дополнительные функции мониторинга доступны напрямую через occtl внутри контейнера.

## Сборка и развертывание

### Локальная сборка
```bash
docker-compose build
docker-compose up -d
```

### Проверка конфигурации
```bash
# Просмотр первых строк конфигурации
docker-compose exec ocserv head -n 50 /etc/ocserv/ocserv.conf

# Проверка наличия secrets
docker-compose exec ocserv ls -l /run/secrets | grep ocserv_
```

## Мониторинг и метрики

Используется [ocserv-exporter от Criteo](https://github.com/criteo/ocserv-exporter).

### Доступные метрики
- **Эндпоинт**: `http://localhost:8000/metrics`
- **VPN метрики**: активные сессии, аутентификация, трафик
- **Go runtime**: память, GC, goroutines

### Основные метрики VPN:
```
vpn_active_sessions          - Текущие подключения
vpn_authentication_failures - Ошибки аутентификации  
vpn_rx_bytes / vpn_tx_bytes - Объем трафика
vpn_start_time_seconds      - Время запуска сервера
```

### Просмотр метрик:
```bash
# Прямой запрос метрик
curl http://localhost:8000/metrics

# Через Docker
docker exec ocserv-docker wget -q -O - http://localhost:8000/metrics
```

### Мониторинг логов:
```bash
# Просмотр логов контейнера
docker logs ocserv-docker -f

# Системные логи OCServ
docker exec ocserv-docker tail -f /var/log/messages | grep ocserv
```

### Интеграция с Prometheus:
```yaml
scrape_configs:
  - job_name: 'ocserv'
    static_configs:
      - targets: ['ocserv-host:8000']
    scrape_interval: 30s
```

## Troubleshooting

### Проблемы с правами доступа
Убедитесь, что контейнер запущен в привилегированном режиме:
```yaml
privileged: true
```

### Проблемы с сертификатами
Удалите существующие сертификаты для перегенерации:
```bash
docker-compose exec ocserv rm -f /etc/ocserv/certs/*
docker-compose restart ocserv
```

### Проблемы с сетью
Проверьте настройки iptables на хосте и убедитесь, что IP forwarding включен.

## Безопасность

- Используйте сильные пароли для пользователей
- Регулярно обновляйте образ контейнера
- Мониторьте логи на предмет подозрительной активности
- Рассмотрите использование внешнего RADIUS сервера для аутентификации

## Лицензия

Этот проект использует OCServ под лицензией GPL v2.
