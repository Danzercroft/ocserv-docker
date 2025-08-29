#!/bin/sh

# Официальный ocserv-exporter от Criteo
# https://github.com/criteo/ocserv-exporter

echo "Starting official ocserv-exporter on port ${METRICS_PORT:-8000}"

# Установка значений по умолчанию
METRICS_PORT="${METRICS_PORT:-8000}"
METRICS_INTERVAL="${METRICS_INTERVAL:-30}"

# Проверяем, что ocserv-exporter доступен
if ! command -v ocserv-exporter >/dev/null 2>&1; then
    echo "ERROR: ocserv-exporter not found in PATH"
    exit 1
fi

# Функция для остановки экспортера
cleanup() {
    echo "Stopping ocserv-exporter..."
    if [ -f /var/run/ocserv-exporter.pid ]; then
        kill $(cat /var/run/ocserv-exporter.pid) 2>/dev/null || true
        rm -f /var/run/ocserv-exporter.pid
    fi
    exit 0
}

# Обработка сигналов
trap cleanup TERM INT

# Ожидание запуска OCServ
echo "Waiting for OCServ to start..."
while ! pgrep ocserv >/dev/null 2>&1; do
    sleep 2
    echo "Waiting for OCServ..."
done

echo "OCServ is running, starting metrics exporter..."

# Запуск официального ocserv-exporter
echo "Starting ocserv-exporter with parameters:"
echo "  Listen address: 0.0.0.0:${METRICS_PORT}"
echo "  Scrape interval: ${METRICS_INTERVAL}s"

# Запуск экспортера в background и сохранение PID
ocserv-exporter \
    -listen "0.0.0.0:${METRICS_PORT}" \
    -interval "${METRICS_INTERVAL}s" &

echo $! > /var/run/ocserv-exporter.pid

# Ожидание завершения
wait
