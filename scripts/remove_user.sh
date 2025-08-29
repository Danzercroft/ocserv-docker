#!/bin/bash

# Скрипт для удаления пользователя VPN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWD_FILE="$SCRIPT_DIR/../config/passwd"

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция помощи
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ] USERNAME

Удаление пользователя VPN из ocserv.

ОПЦИИ:
    -f, --force               Удалить без подтверждения
    -h, --help                Показать эту справку

ПРИМЕРЫ:
    $0 john                   # Удалить пользователя john (с подтверждением)
    $0 -f jane               # Удалить пользователя jane без подтверждения

EOF
}

# Парсинг аргументов
USERNAME=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Неизвестная опция: $1" >&2
            show_help
            exit 1
            ;;
        *)
            if [ -z "$USERNAME" ]; then
                USERNAME="$1"
            else
                echo "Слишком много аргументов" >&2
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Проверка имени пользователя
if [ -z "$USERNAME" ]; then
    echo "Ошибка: Необходимо указать имя пользователя" >&2
    show_help
    exit 1
fi

# Проверка что файл passwd существует
if [ ! -f "$PASSWD_FILE" ]; then
    echo "Ошибка: Файл паролей не найден: $PASSWD_FILE" >&2
    exit 1
fi

# Проверка что пользователь существует
if ! grep -q "^$USERNAME:" "$PASSWD_FILE"; then
    echo "Ошибка: Пользователь $USERNAME не найден" >&2
    exit 1
fi

# Подтверждение удаления
if [ "$FORCE" = false ]; then
    echo -n "Вы уверены, что хотите удалить пользователя $USERNAME? (y/N): "
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Отменено"
        exit 0
    fi
fi

# Создание резервной копии
BACKUP_FILE="${PASSWD_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
log "Создание резервной копии: $BACKUP_FILE"
cp "$PASSWD_FILE" "$BACKUP_FILE"

# Удаление пользователя
log "Удаление пользователя $USERNAME..."
sed -i "/^$USERNAME:/d" "$PASSWD_FILE"

log "Пользователь $USERNAME успешно удален!"
log "Резервная копия сохранена: $BACKUP_FILE"
log "Для применения изменений перезапустите ocserv:"
log "  docker-compose restart"

# Показать оставшихся пользователей
echo
echo "Оставшиеся пользователи:"
if [ -s "$PASSWD_FILE" ]; then
    cut -d: -f1 "$PASSWD_FILE" | sort
else
    echo "(нет пользователей)"
fi
