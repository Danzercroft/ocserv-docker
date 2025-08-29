#!/bin/bash

# Скрипт для создания нового пользователя VPN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWD_FILE="$SCRIPT_DIR/../config/passwd"

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для генерации хеша пароля
generate_password_hash() {
    local password="$1"
    docker run --rm -i alpine/openssl passwd -6 "$password"
}

# Функция помощи
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ] USERNAME

Создание нового пользователя VPN для ocserv.

ОПЦИИ:
    -p, --password PASSWORD    Пароль пользователя (будет запрошен если не указан)
    -h, --help                Показать эту справку

ПРИМЕРЫ:
    $0 john                   # Создать пользователя john (пароль будет запрошен)
    $0 -p mypass123 jane     # Создать пользователя jane с паролем mypass123

EOF
}

# Парсинг аргументов
USERNAME=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--password)
            PASSWORD="$2"
            shift 2
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

# Проверка формата имени пользователя
if [[ ! "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Ошибка: Имя пользователя может содержать только буквы, цифры, _ и -" >&2
    exit 1
fi

# Запрос пароля если не указан
if [ -z "$PASSWORD" ]; then
    echo -n "Введите пароль для пользователя $USERNAME: "
    read -s PASSWORD
    echo
    
    if [ -z "$PASSWORD" ]; then
        echo "Ошибка: Пароль не может быть пустым" >&2
        exit 1
    fi
    
    echo -n "Подтвердите пароль: "
    read -s PASSWORD_CONFIRM
    echo
    
    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        echo "Ошибка: Пароли не совпадают" >&2
        exit 1
    fi
fi

# Проверка что файл passwd существует
if [ ! -f "$PASSWD_FILE" ]; then
    log "Создание файла паролей: $PASSWD_FILE"
    touch "$PASSWD_FILE"
fi

# Проверка что пользователь не существует
if grep -q "^$USERNAME:" "$PASSWD_FILE" 2>/dev/null; then
    echo "Ошибка: Пользователь $USERNAME уже существует" >&2
    exit 1
fi

# Генерация хеша пароля
log "Генерация хеша пароля..."
PASSWORD_HASH=$(generate_password_hash "$PASSWORD")

if [ -z "$PASSWORD_HASH" ]; then
    echo "Ошибка: Не удалось сгенерировать хеш пароля" >&2
    exit 1
fi

# Добавление пользователя
log "Добавление пользователя $USERNAME..."
echo "$USERNAME:$PASSWORD_HASH" >> "$PASSWD_FILE"

log "Пользователь $USERNAME успешно создан!"
log "Для применения изменений перезапустите ocserv:"
log "  docker-compose restart"

# Показать текущих пользователей
echo
echo "Текущие пользователи:"
if [ -s "$PASSWD_FILE" ]; then
    cut -d: -f1 "$PASSWD_FILE" | sort
else
    echo "(нет пользователей)"
fi
