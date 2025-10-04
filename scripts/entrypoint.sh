#!/bin/sh

# Скрипт запуска ocserv в Docker контейнере (Alpine Linux)

set -e

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Переменные окружения для путей к сертификатам (с дефолтными значениями для Swarm)
SERVER_CERT_PATH="${SERVER_CERT_PATH:-/run/secrets/server_cert}"
SERVER_KEY_PATH="${SERVER_KEY_PATH:-/run/secrets/server_key}"
PASSWD_PATH="${PASSWD_PATH:-/run/secrets/ocserv_passwd}"

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

log "Настройка путей сертификатов в конфигурации..."
# Создаем копию конфига с подстановкой переменных
cp /etc/ocserv/ocserv.conf /tmp/ocserv.conf
sed -i "s|@SERVER_CERT_PATH@|$SERVER_CERT_PATH|g" /tmp/ocserv.conf
sed -i "s|@SERVER_KEY_PATH@|$SERVER_KEY_PATH|g" /tmp/ocserv.conf
sed -i "s|@PASSWD_PATH@|$PASSWD_PATH|g" /tmp/ocserv.conf

# Проверка файла паролей (secret)
if [ ! -f "$PASSWD_PATH" ]; then
    log "ОШИБКА: Файл с паролями не найден: $PASSWD_PATH"
    exit 1
fi

# Проверка обязательных SSL сертификатов
log "Проверка SSL сертификатов..."
if [ ! -f "$SERVER_CERT_PATH" ]; then
    log "ОШИБКА: Сертификат сервера не найден: $SERVER_CERT_PATH"
    exit 1
fi
if [ ! -f "$SERVER_KEY_PATH" ]; then
    log "ОШИБКА: Приватный ключ сервера не найден: $SERVER_KEY_PATH"
    exit 1
fi

# Проверка прав доступа к сертификатам
if [ ! -r "$SERVER_CERT_PATH" ] || [ ! -r "$SERVER_KEY_PATH" ]; then
    log "ОШИБКА: Недостаточно прав для чтения сертификатов"
    exit 1
fi

log "SSL сертификаты найдены и доступны:"
log "  Сертификат сервера: $SERVER_CERT_PATH"
log "  Приватный ключ: $SERVER_KEY_PATH"

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

# Запуск в foreground режиме с обработанной конфигурацией
exec ocserv --foreground --pid-file /var/run/ocserv.pid --config /tmp/ocserv.conf
