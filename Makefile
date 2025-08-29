# Makefile для управления ocserv Docker проектом

.PHONY: help build start stop restart logs status users clean add-user remove-user metrics monitor

# Переменные
CONTAINER_NAME = ocserv-vpn
IMAGE_NAME = ocserv_docker-ocserv
DOCKER_COMPOSE = docker-compose

# Цель по умолчанию
help: ## Показать справку
	@echo "Доступные команды:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Собрать Docker образ
	@echo "Сборка Docker образа..."
	$(DOCKER_COMPOSE) build --no-cache

start: ## Запустить сервер
	@echo "Запуск ocserv сервера..."
	$(DOCKER_COMPOSE) up -d

stop: ## Остановить сервер
	@echo "Остановка ocserv сервера..."
	$(DOCKER_COMPOSE) down

restart: ## Перезапустить сервер
	@echo "Перезапуск ocserv сервера..."
	$(DOCKER_COMPOSE) restart

logs: ## Показать логи
	@echo "Логи ocserv сервера:"
	$(DOCKER_COMPOSE) logs -f

status: ## Показать статус сервера
	@echo "Статус контейнера:"
	@docker ps | grep $(CONTAINER_NAME) || echo "Контейнер не запущен"
	@echo "\nПроцессы внутри контейнера:"
	@docker exec $(CONTAINER_NAME) ps aux 2>/dev/null || echo "Не удалось получить список процессов"

users: ## Показать подключенных пользователей
	@echo "Подключенные пользователи:"
	@docker exec $(CONTAINER_NAME) occtl show users 2>/dev/null || echo "OCServ не запущен или нет подключений"

metrics: ## Показать метрики Prometheus
	@echo "Получение метрик OCServ..."
	@curl -s http://localhost:8000/metrics | grep -E "^vpn_" || echo "Экспортер метрик недоступен на порту 8000"

metrics-raw: ## Показать все метрики (включая Go runtime)
	@echo "Все метрики с ocserv-exporter:"
	@curl -s http://localhost:8000/metrics || echo "Экспортер метрик недоступен на порту 8000"

monitor: ## Запустить мониторинг
	@./scripts/monitor.sh

add-user: ## Добавить пользователя (использование: make add-user USER=username)
	@if [ -z "$(USER)" ]; then \
		echo "Использование: make add-user USER=username"; \
		exit 1; \
	fi
	@./scripts/add_user.sh $(USER)

remove-user: ## Удалить пользователя (использование: make remove-user USER=username)
	@if [ -z "$(USER)" ]; then \
		echo "Использование: make remove-user USER=username"; \
		exit 1; \
	fi
	@./scripts/remove_user.sh $(USER)

clean: ## Очистить контейнеры и образы
	@echo "Остановка и удаление контейнеров..."
	$(DOCKER_COMPOSE) down --rmi all --volumes --remove-orphans

reset: clean build start ## Полный сброс (остановка, очистка, сборка, запуск)

shell: ## Войти в контейнер
	@docker exec -it $(CONTAINER_NAME) /bin/sh

config-test: ## Проверить конфигурацию OCServ
	@echo "Проверка конфигурации ocserv..."
	@docker exec $(CONTAINER_NAME) ocserv -t -c /etc/ocserv/ocserv.conf 2>/dev/null || echo "Не удалось проверить конфигурацию"

syslog: ## Показать системные логи OCServ
	@echo "Системные логи OCServ:"
	@docker exec $(CONTAINER_NAME) tail -f /var/log/messages | grep -i ocserv

backup: ## Создать резервную копию конфигурации
	@echo "Создание резервной копии..."
	@tar -czf backup-$(shell date +%Y%m%d_%H%M%S).tar.gz config/ scripts/ .env docker-compose.yml Dockerfile *.md

setup: ## Первоначальная настройка
	@echo "Первоначальная настройка ocserv..."
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@chmod +x scripts/*.sh
	@mkdir -p certs
	@echo "Настройка завершена. Отредактируйте .env и config/passwd, добавьте SSL сертификаты в certs/, затем запустите 'make start'"

test: ## Тестирование функциональности
	@echo "Тестирование OCServ..."
	@echo "1. Проверка контейнера:"
	@make status
	@echo "\n2. Проверка метрик:"
	@make metrics
	@echo "\n3. Проверка конфигурации:"
	@make config-test
