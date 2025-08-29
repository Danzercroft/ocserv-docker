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
    log "Настройка IP forwarding..."
    # Используем sysctl вместо прямой записи в файл
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || echo "ПРЕДУПРЕЖДЕНИЕ: Не удалось включить IP forwarding. Возможно, требуются дополнительные привилегии."
    
    log "Настройка iptables NAT..."
    iptables -t nat -A POSTROUTING -s 10.10.10.1/24 -o eth0 -j MASQUERADE || true
    iptables -A FORWARD -s 10.10.10.1/24 -j ACCEPT || true
    iptables -A FORWARD -d 10.10.10.1/24 -j ACCEPT || true
fi

# Установка значений по умолчанию для переменных окружения
VPN_SERVER_CERT="${VPN_SERVER_CERT:-/etc/ocserv/certs/server.crt}"
VPN_SERVER_KEY="${VPN_SERVER_KEY:-/etc/ocserv/certs/server.key}"
VPN_CA_CERT="${VPN_CA_CERT:-/etc/ocserv/certs/ca.crt}"
VPN_DOMAIN="${VPN_DOMAIN:-my-vpn-server.local}"
VPN_IPV4_NETWORK="${VPN_IPV4_NETWORK:-10.10.10.0}"
VPN_IPV4_NETMASK="${VPN_IPV4_NETMASK:-255.255.255.0}"
VPN_IPV6_NETWORK="${VPN_IPV6_NETWORK:-fda9:4efe:7e3b:03ea::/48}"
VPN_IPV6_PREFIX="${VPN_IPV6_PREFIX:-64}"
VPN_TCP_PORT="${VPN_TCP_PORT:-443}"
VPN_UDP_PORT="${VPN_UDP_PORT:-443}"
VPN_MAX_CLIENTS="${VPN_MAX_CLIENTS:-128}"
VPN_MAX_SAME_CLIENTS="${VPN_MAX_SAME_CLIENTS:-10}"
VPN_KEEPALIVE="${VPN_KEEPALIVE:-30}"
VPN_DPD="${VPN_DPD:-60}"
VPN_MOBILE_DPD="${VPN_MOBILE_DPD:-300}"
VPN_AUTH_TIMEOUT="${VPN_AUTH_TIMEOUT:-240}"
VPN_COOKIE_TIMEOUT="${VPN_COOKIE_TIMEOUT:-300}"
VPN_REKEY_TIME="${VPN_REKEY_TIME:-172800}"
VPN_DNS1="${VPN_DNS1:-8.8.8.8}"
VPN_DNS2="${VPN_DNS2:-1.1.1.1}"
VPN_TUNNEL_ALL_DNS="${VPN_TUNNEL_ALL_DNS:-true}"
VPN_BAN_SCORE="${VPN_BAN_SCORE:-80}"
VPN_BAN_RESET_TIME="${VPN_BAN_RESET_TIME:-300}"
VPN_MIN_REAUTH_TIME="${VPN_MIN_REAUTH_TIME:-300}"
VPN_COMPRESSION="${VPN_COMPRESSION:-true}"
VPN_CISCO_COMPAT="${VPN_CISCO_COMPAT:-true}"
VPN_LOG_LEVEL="${VPN_LOG_LEVEL:-1}"
VPN_ROUTES="${VPN_ROUTES:-}"
VPN_NO_ROUTES="${VPN_NO_ROUTES:-}"

# Генерация конфигурации из шаблона
log "Генерация конфигурации из шаблона..."
if [ ! -f /etc/ocserv/ocserv.conf.template ]; then
    log "ОШИБКА: Шаблон конфигурации /etc/ocserv/ocserv.conf.template не найден!"
    exit 1
fi

# Подстановка переменных в шаблон
envsubst < /etc/ocserv/ocserv.conf.template > /etc/ocserv/ocserv.conf

# Обработка маршрутов
if [ -n "$VPN_ROUTES" ]; then
    log "Добавление пользовательских маршрутов: $VPN_ROUTES"
    echo "$VPN_ROUTES" | tr ',' '\n' | while read -r route; do
        if [ -n "$route" ]; then
            sed -i "s|# ROUTES_PLACEHOLDER|route = $route\n# ROUTES_PLACEHOLDER|" /etc/ocserv/ocserv.conf
        fi
    done
fi

# Обработка no-routes
if [ -n "$VPN_NO_ROUTES" ]; then
    log "Добавление ограничений маршрутов: $VPN_NO_ROUTES"
    echo "$VPN_NO_ROUTES" | tr ',' '\n' | while read -r no_route; do
        if [ -n "$no_route" ]; then
            sed -i "s|# NO_ROUTES_PLACEHOLDER|no-route = $no_route\n# NO_ROUTES_PLACEHOLDER|" /etc/ocserv/ocserv.conf
        fi
    done
fi

# Очистка плейсхолдеров
sed -i '/# ROUTES_PLACEHOLDER/d' /etc/ocserv/ocserv.conf
sed -i '/# NO_ROUTES_PLACEHOLDER/d' /etc/ocserv/ocserv.conf

log "Конфигурация сгенерирована успешно"

# Проверка файла паролей
if [ ! -f /etc/ocserv/passwd ]; then
    log "ОШИБКА: Файл паролей /etc/ocserv/passwd не найден!"
    exit 1
fi

# Проверка обязательных SSL сертификатов
log "Проверка SSL сертификатов..."
if [ ! -f "$VPN_SERVER_CERT" ]; then
    log "ОШИБКА: Файл сертификата сервера не найден: $VPN_SERVER_CERT"
    log "Убедитесь, что сертификаты смонтированы в /etc/ocserv/certs/"
    exit 1
fi

if [ ! -f "$VPN_SERVER_KEY" ]; then
    log "ОШИБКА: Файл приватного ключа сервера не найден: $VPN_SERVER_KEY"
    log "Убедитесь, что сертификаты смонтированы в /etc/ocserv/certs/"
    exit 1
fi

if [ ! -f "$VPN_CA_CERT" ]; then
    log "ОШИБКА: Файл CA сертификата не найден: $VPN_CA_CERT"
    log "Убедитесь, что сертификаты смонтированы в /etc/ocserv/certs/"
    exit 1
fi

# Проверка прав доступа к сертификатам
if [ ! -r "$VPN_SERVER_CERT" ] || [ ! -r "$VPN_SERVER_KEY" ] || [ ! -r "$VPN_CA_CERT" ]; then
    log "ОШИБКА: Недостаточно прав для чтения файлов сертификатов"
    exit 1
fi

log "SSL сертификаты найдены и доступны:"
log "  Сертификат сервера: $VPN_SERVER_CERT"
log "  Приватный ключ: $VPN_SERVER_KEY"
log "  CA сертификат: $VPN_CA_CERT"

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

# Запуск metrics exporter если включен
if [ "${ENABLE_METRICS:-true}" = "true" ]; then
    log "Запуск официального ocserv-exporter на порту ${METRICS_PORT:-8000}..."
    /metrics-exporter.sh &
fi

# Запуск ocserv
log "Запуск ocserv..."
log "Конфигурация: /etc/ocserv/ocserv.conf"
log "Домен: $DOMAIN"
log "Порт: 443"

# Запуск в foreground режиме
exec ocserv --foreground --pid-file /var/run/ocserv.pid --config /etc/ocserv/ocserv.conf
