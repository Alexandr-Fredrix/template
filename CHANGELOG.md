# Changelog

Все важные изменения в этом проекте будут документированы в этом файле.

## [Unreleased]

## [1.1.0] - 2026-01-31

### Added
- **Ansible подробные примеры использования**
  - USAGE_GUIDE.md с полным руководством
  - EXAMPLES.md с 12 практическими сценариями
  - Готовые роли: common, webserver, database
  - Production и staging inventory
  - Group vars для всех типов серверов
  - Playbooks для деплоя с rollback
  - Templates для Nginx, PostgreSQL, SSH

- **GitLab CI/CD расширенные примеры**
  - Docker executor с тестами и линтерами
  - Kubernetes executor с Kaniko
  - Complete testing pipeline (unit, integration, e2e, performance)
  - Security scanning (Trivy, SAST, secrets)
  - README-EXECUTORS.md с детальным гайдом
  - Конфигурационные файлы (.eslintrc, jest.config, pytest.ini)

## [1.0.0] - 2026-01-31

### Added
- **Helm Charts**
  - Полный production-ready шаблон веб-приложения
  - Подробный README с гайдом
  - Все необходимые templates (Deployment, Service, Ingress, HPA, PDB, RBAC)

- **Dockerfiles**
  - Node.js (стандартный, TypeScript, Next.js)
  - Python (стандартный, Django, FastAPI)
  - Go (multi-stage с scratch)
  - Java (Spring Boot Maven/Gradle)
  - PHP (с Nginx)
  - .NET (ASP.NET Core)
  - Rust (оптимизированная сборка)

- **Docker Compose**
  - Full-stack приложение
  - Monitoring стек (Prometheus, Grafana, Loki)
  - WordPress
  - Микросервисная архитектура

- **Kubernetes Manifests**
  - Полный набор production-ready манифестов
  - 11 файлов с примерами всех ресурсов

- **ArgoCD**
  - Application манифесты
  - ApplicationSets для multi-cluster
  - App of Apps pattern

- **Документация**
  - README.md
  - QUICK_START.md
  - CONTRIBUTING.md
  - LICENSE

## Типы изменений
- `Added` - новые функции
- `Changed` - изменения существующей функциональности
- `Deprecated` - функции которые скоро будут удалены
- `Removed` - удаленные функции
- `Fixed` - исправления багов
- `Security` - исправления уязвимостей
