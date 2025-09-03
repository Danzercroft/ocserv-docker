# Changelog

## [Unreleased]

### Added
- Реализована поддержка Docker Compose configs и secrets
- Добавлен статический конфигурационный файл `ocserv.conf` с разумными значениями по умолчанию
- Добавлена документация по использованию configs и secrets

### Changed
- **BREAKING CHANGE**: Заменен шаблон `ocserv.conf.template` статическим файлом `ocserv.conf`
- Значительно сокращен список переменных окружения (с 25+ до 8 основных)
- Адаптация под Docker Swarm: переход на стандартные пути `/run/secrets/*`
- Упрощение: удалены переменные портов/сети/маршрутов; статический конфиг без runtime правок
- Дополнительно: удалены все ENV кроме метрик (ENABLE_METRICS, METRICS_PORT, METRICS_INTERVAL)
- OCServ конфигурация теперь монтируется как config вместо volume
- SSL сертификаты и файл паролей монтируются как secrets
- Обновлен Dockerfile для исключения копирования конфигурационных файлов в образ
- Переименован проект в `ocserv-docker`
- Обновлено имя Docker образа с `danzercroft/ocserv` на `danzercroft/ocserv-docker`
- Обновлено имя контейнера с `ocserv-vpn` на `ocserv-docker`
- Обновлены ссылки на GitHub репозиторий
- Исправлен GitHub Actions workflow для публикации в Docker Hub

### Security
- Повышена безопасность: секретные файлы больше не копируются в Docker образ
- Автоматическая установка корректных прав доступа для secrets (0600 для ключей и паролей)

### Removed
- Удален файл шаблона `ocserv.conf.template`
- Удалено большинство переменных окружения (теперь используются встроенные значения по умолчанию)
- Убраны переменные сертификатов `VPN_SERVER_CERT`, `VPN_SERVER_KEY`, `VPN_CA_CERT` (используются secrets)
- Удалены скрипты `scripts/add_user.sh` и `scripts/remove_user.sh` (файл паролей теперь исключительно secret и управляется вне контейнера)
- Удалены вспомогательные скрипты `monitor.sh` и `metrics-exporter.sh` (логика экспортера сведена к простому запуску из entrypoint либо может быть перенесена позже внутрь ocserv)

### Repository
- GitHub: https://github.com/Danzercroft/ocserv-docker
- Docker Hub: https://hub.docker.com/r/danzercroft/ocserv-docker

## [1.0.0] - 2025-08-29

### Added
- Первоначальный релиз OCServ Docker контейнера
- Поддержка настройки через переменные окружения
- Интеграция с Prometheus метриками
- Автоматическая сборка через GitHub Actions
- Полная документация и руководство по быстрому старту
