#!/bin/sh

# Скрипт запуска ocserv в Docker контейнере (Alpine Linux)

set -e

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Проверка и создание необходимых директорий
log "Создание необходимых директорий..."
mkdir -p /var/run

# Настройка iptables для NAT (если включен привилегированный режим)
if [ -f /proc/sys/net/ipv4/ip_forward ]; then
    log "IP forwarding ожидается включенным (установлено через docker sysctls). Пропуск ручной настройки."
    
    log "Настройка iptables NAT..."
    iptables -t nat -A POSTROUTING -s 10.10.10.1/24 -o eth0 -j MASQUERADE || true
    iptables -A FORWARD -s 10.10.10.1/24 -j ACCEPT || true
    iptables -A FORWARD -d 10.10.10.1/24 -j ACCEPT || true
fi


# Проверка конфигурационного файла
log "Проверка конфигурации OCServ..."
if [ ! -f /etc/ocserv/ocserv.conf ]; then
    log "ОШИБКА: Конфигурационный файл /etc/ocserv/ocserv.conf не найден!"
    exit 1
fi

log "Статическая конфигурация используется без модификаций (вариант 1)."

# Проверка файла паролей (secret)
if [ ! -f /run/secrets/ocserv_passwd ]; then
    log "ОШИБКА: Secret с паролями /run/secrets/ocserv_passwd не найден!"
    exit 1
fi

# Проверка обязательных SSL сертификатов
log "Проверка SSL сертификатов (secrets)..."
if [ ! -f "/run/secrets/server_cert" ]; then
    log "ОШИБКА: Secret server_cert не найден в /run/secrets/server_cert"
    exit 1
fi
if [ ! -f "/run/secrets/server_key" ]; then
    log "ОШИБКА: Secret server_key не найден в /run/secrets/server_key"
    exit 1
fi
if [ ! -f "/run/secrets/ca_cert" ]; then
    log "ОШИБКА: Secret ca_cert не найден в /run/secrets/ca_cert"
    exit 1
fi

# Проверка прав доступа к сертификатам
if [ ! -r "/run/secrets/server_cert" ] || [ ! -r "/run/secrets/server_key" ] || [ ! -r "/run/secrets/ca_cert" ]; then
    log "ОШИБКА: Недостаточно прав для чтения secrets сертификатов"
    exit 1
fi

log "SSL сертификаты (secrets) найдены и доступны:"
log "  Сертификат сервера: /run/secrets/server_cert"
log "  Приватный ключ: /run/secrets/server_key"
log "  CA сертификат: /run/secrets/ca_cert"

# Функция для остановки сервера
cleanup() {
    log "Получен сигнал завершения, останавливаем сервисы..."
    
    # Остановка ocserv-exporter
    if [ -f /var/run/ocserv-exporter.pid ]; then
        kill $(cat /var/run/ocserv-exporter.pid) 2>/dev/null || true
        rm -f /var/run/ocserv-exporter.pid
    fi
    
    # Остановка OCServ
    if [ -f /var/run/ocserv.pid ]; then
        kill -TERM $(cat /var/run/ocserv.pid) 2>/dev/null || true
    fi
    exit 0
}

# Обработка сигналов
trap cleanup TERM INT

start_metrics() {
    if [ "${ENABLE_METRICS:-true}" != "true" ]; then
        return 0
    fi
    METRICS_PORT="${METRICS_PORT:-8000}"
    METRICS_INTERVAL="${METRICS_INTERVAL:-30}"
    if ! command -v ocserv-exporter >/dev/null 2>&1; then
        log "ocserv-exporter не найден – метрики отключены"
        return 0
    fi
    (
        log "Ожидание запуска ocserv перед стартом экспортера..."
        while ! pgrep ocserv >/dev/null 2>&1; do
            sleep 2
        done
        log "ocserv запущен; старт экспортера метрик на порту ${METRICS_PORT} (interval=${METRICS_INTERVAL}s)"
        ocserv-exporter -listen "0.0.0.0:${METRICS_PORT}" -interval "${METRICS_INTERVAL}s" &
        echo $! > /var/run/ocserv-exporter.pid
        wait
    ) &
}

start_metrics

# Запуск ocserv
log "Запуск ocserv..."
log "Конфигурация: /etc/ocserv/ocserv.conf"
log "Порт: 443 (TCP/UDP)"

# Запуск в foreground режиме
exec ocserv --foreground --pid-file /var/run/ocserv.pid --config /etc/ocserv/ocserv.conf
