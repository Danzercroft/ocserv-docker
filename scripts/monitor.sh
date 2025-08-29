#!/bin/bash

# Скрипт для мониторинга ocserv-docker сервера

set -e

CONTAINER_NAME="ocserv-docker"

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция помощи
show_help() {
    cat << EOF
Использование: $0 [КОМАНДА]

Мониторинг и управление ocserv VPN сервером.

КОМАНДЫ:
    status          Показать статус сервера и подключений
    users           Показать подключенных пользователей
    logs            Показать логи сервера
    stats           Показать статистику сервера
    restart         Перезапустить сервер
    stop            Остановить сервер
    start           Запустить сервер
    help            Показать эту справку

ПРИМЕРЫ:
    $0 status       # Показать статус
    $0 users        # Показать подключенных пользователей
    $0 logs         # Показать последние логи

EOF
}

# Проверка что контейнер существует
check_container() {
    if ! docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        echo "Ошибка: Контейнер $CONTAINER_NAME не найден" >&2
        echo "Запустите: docker-compose up -d" >&2
        exit 1
    fi
}

# Проверка что контейнер запущен
check_running() {
    if ! docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        echo "Ошибка: Контейнер $CONTAINER_NAME не запущен" >&2
        echo "Запустите: docker-compose start" >&2
        exit 1
    fi
}

# Команда status
cmd_status() {
    check_container
    
    echo "=== Статус контейнера ==="
    if docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        echo "Статус: Запущен"
        
        # Время работы
        UPTIME=$(docker ps --format "{{.Status}}" --filter "name=$CONTAINER_NAME")
        echo "Время работы: $UPTIME"
        
        # Использование ресурсов
        echo ""
        echo "=== Использование ресурсов ==="
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $CONTAINER_NAME
        
    else
        echo "Статус: Остановлен"
    fi
    
    echo ""
    echo "=== Сетевые порты ==="
    docker port $CONTAINER_NAME 2>/dev/null || echo "Порты не проброшены"
}

# Команда users
cmd_users() {
    check_running
    
    echo "=== Подключенные пользователи ==="
    if docker exec $CONTAINER_NAME occtl show users 2>/dev/null; then
        echo ""
        echo "=== Статистика подключений ==="
        docker exec $CONTAINER_NAME occtl show status 2>/dev/null || true
    else
        echo "Нет подключенных пользователей или occtl недоступен"
    fi
}

# Команда logs
cmd_logs() {
    check_container
    
    echo "=== Логи контейнера (последние 50 строк) ==="
    docker logs --tail 50 $CONTAINER_NAME
    
    echo ""
    echo "=== Логи ocserv ==="
    docker exec $CONTAINER_NAME sh -c 'if [ -f /var/log/ocserv/ocserv.log ]; then tail -20 /var/log/ocserv/ocserv.log; else echo "Лог файл не найден"; fi' 2>/dev/null || echo "Не удалось получить логи ocserv"
}

# Команда stats
cmd_stats() {
    check_running
    
    echo "=== Статистика сервера ==="
    docker exec $CONTAINER_NAME occtl show status 2>/dev/null || echo "Статистика недоступна"
    
    echo ""
    echo "=== Информация о сервере ==="
    docker exec $CONTAINER_NAME occtl show info 2>/dev/null || echo "Информация недоступна"
}

# Команда restart
cmd_restart() {
    check_container
    log "Перезапуск сервера..."
    docker-compose restart
    log "Сервер перезапущен"
}

# Команда stop
cmd_stop() {
    check_container
    log "Остановка сервера..."
    docker-compose stop
    log "Сервер остановлен"
}

# Команда start
cmd_start() {
    check_container
    log "Запуск сервера..."
    docker-compose start
    log "Сервер запущен"
}

# Основная логика
COMMAND="${1:-status}"

case $COMMAND in
    status)
        cmd_status
        ;;
    users)
        cmd_users
        ;;
    logs)
        cmd_logs
        ;;
    stats)
        cmd_stats
        ;;
    restart)
        cmd_restart
        ;;
    stop)
        cmd_stop
        ;;
    start)
        cmd_start
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Неизвестная команда: $COMMAND" >&2
        show_help
        exit 1
        ;;
esac
