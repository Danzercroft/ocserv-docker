# OCServ Docker Project

Контейнер OCServ VPN сервера на базе Alpine Linux с полной поддержкой настройки через переменные окружения.

## Возможности

- 🔧 **Настройка через ENV переменные** - Все основные параметры OCServ настраиваются через .env файл
- 🔒 **Автоматическое создание сертификатов** - Генерация SSL сертификатов для заданного домена
- 🐧 **Alpine Linux** - Минимальный размер образа
- 📦 **Компиляция из исходников** - OCServ собирается из master ветки GitLab
- 🔗 **Поддержка AnyConnect** - Совместимость с Cisco AnyConnect клиентами
- 🌐 **Гибкая настройка сети** - Настройка IP диапазонов, DNS, маршрутизации

## Быстрый старт

1. **Клонируйте проект:**
```bash
git clone <your-repo>
cd ocserv_docker
```

2. **Подготовьте SSL сертификаты:**
```bash
# Поместите ваши сертификаты в директорию certs/
cp your-server.crt certs/server.crt
cp your-server.key certs/server.key  
cp your-ca.crt certs/ca.crt

# Или создайте тестовые самоподписанные сертификаты
cd certs && openssl genrsa -out server.key 3072
openssl req -new -key server.key -out server.csr -subj "/CN=vpn.example.com"
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt
cp server.crt ca.crt && rm server.csr && cd ..
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

## Настройка через ENV переменные

Все настройки OCServ конфигурируются через переменные окружения в файле `.env`:

### Основные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_DOMAIN` | `my-vpn-server.local` | Домен VPN сервера (только для логов) |
| `VPN_TCP_PORT` | `443` | TCP порт OCServ |
| `VPN_UDP_PORT` | `443` | UDP порт OCServ |

### SSL Сертификаты

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_SERVER_CERT` | `/etc/ocserv/certs/server.crt` | Путь к сертификату сервера |
| `VPN_SERVER_KEY` | `/etc/ocserv/certs/server.key` | Путь к приватному ключу |
| `VPN_CA_CERT` | `/etc/ocserv/certs/ca.crt` | Путь к CA сертификату |

### Настройки сети

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_IPV4_NETWORK` | `10.10.10.0` | IPv4 сеть VPN |
| `VPN_IPV4_NETMASK` | `255.255.255.0` | Маска подсети IPv4 |
| `VPN_IPV6_NETWORK` | `fda9:4efe:7e3b:03ea::/48` | IPv6 сеть VPN |
| `VPN_IPV6_PREFIX` | `64` | Префикс IPv6 подсети |
| `VPN_DNS1` | `8.8.8.8` | Первичный DNS сервер |
| `VPN_DNS2` | `1.1.1.1` | Вторичный DNS сервер |
| `VPN_TUNNEL_ALL_DNS` | `true` | Туннелировать все DNS запросы |

### Настройки клиентов

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_MAX_CLIENTS` | `128` | Максимум подключений |
| `VPN_MAX_SAME_CLIENTS` | `10` | Максимум с одного IP |

### Настройки сессий

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_KEEPALIVE` | `30` | Интервал keepalive (сек) |
| `VPN_DPD` | `60` | Dead Peer Detection (сек) |
| `VPN_MOBILE_DPD` | `300` | DPD для мобильных (сек) |
| `VPN_AUTH_TIMEOUT` | `240` | Таймаут аутентификации (сек) |
| `VPN_COOKIE_TIMEOUT` | `300` | Время жизни cookie (сек) |
| `VPN_REKEY_TIME` | `172800` | Интервал перегенерации ключей (сек) |

### Настройки безопасности

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_BAN_SCORE` | `80` | Порог для блокировки IP |
| `VPN_BAN_RESET_TIME` | `300` | Время сброса счетчика бана (сек) |
| `VPN_MIN_REAUTH_TIME` | `300` | Минимальное время повторной аутентификации (сек) |

### Дополнительные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_COMPRESSION` | `true` | Включить сжатие трафика |
| `VPN_CISCO_COMPAT` | `true` | Совместимость с AnyConnect |
| `VPN_LOG_LEVEL` | `1` | Уровень логирования (0-10) |

### Маршрутизация

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `VPN_ROUTES` | `` | Дополнительные маршруты (через запятую) |
| `VPN_NO_ROUTES` | `` | Исключения маршрутов (через запятую) |

## Примеры настройки

### Базовая настройка для домена

```bash
# В .env файле
VPN_DOMAIN=vpn.mycompany.com
VPN_IPV4_NETWORK=192.168.100.0
VPN_IPV4_NETMASK=255.255.255.0
VPN_MAX_CLIENTS=50
```

### Настройка с собственными маршрутами

```bash
# В .env файле
VPN_ROUTES=192.168.1.0/24,10.0.0.0/8
VPN_NO_ROUTES=192.168.1.100/32,192.168.1.200/32
```

### Настройка для мобильных клиентов

```bash
# В .env файле
VPN_MOBILE_DPD=1800
VPN_KEEPALIVE=60
VPN_COMPRESSION=true
```

## Управление пользователями

Пользователи настраиваются в файле `config/passwd`. Формат:
```
username:password_hash:дополнительная_информация
```

Для генерации хеша пароля:
```bash
openssl passwd -1 "ваш_пароль"
```

## Логи и мониторинг

Проект поддерживает расширенную систему мониторинга с официальным экспортером метрик.

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

Доступ к метрикам через официальный ocserv-exporter:
```bash
# Просмотр метрик
curl http://localhost:8000/metrics

# Проверка статуса экспортера
docker-compose exec ocserv pgrep ocserv-exporter
```

Подробная информация о мониторинге доступна в [MONITORING.md](MONITORING.md).

## Сборка и развертывание

### Локальная сборка
```bash
docker-compose build
docker-compose up -d
```

### Проверка конфигурации
```bash
# Проверка сгенерированной конфигурации
docker-compose exec ocserv cat /etc/ocserv/ocserv.conf

# Проверка сертификатов
docker-compose exec ocserv ls -la /etc/ocserv/certs/
```

## Мониторинг и метрики

Проект включает официальный [ocserv-exporter от Criteo](https://github.com/criteo/ocserv-exporter) для мониторинга через Prometheus.

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
docker exec ocserv-vpn wget -q -O - http://localhost:8000/metrics
```

### Мониторинг логов:
```bash
# Просмотр логов контейнера
docker logs ocserv-vpn -f

# Системные логи OCServ
docker exec ocserv-vpn tail -f /var/log/messages | grep ocserv
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
