# GitLab CI/CD Executors - Подробное руководство

## 📖 Типы Executors

GitLab Runner поддерживает несколько типов executors:

### 1. Shell Executor
Выполняет команды напрямую на машине runner'а.

### 2. Docker Executor ⭐
Самый популярный. Каждый job запускается в отдельном Docker контейнере.

### 3. Kubernetes Executor ⭐
Запускает jobs как pods в Kubernetes кластере.

### 4. Docker Machine Executor
Автоматически создает Docker hosts для выполнения jobs.

## 🐳 Docker Executor

### Преимущества
- ✅ Изоляция jobs
- ✅ Чистое окружение для каждого job
- ✅ Быстрая настройка
- ✅ Поддержка Docker-in-Docker (dind)

### Конфигурация Runner

```toml
# /etc/gitlab-runner/config.toml
[[runners]]
  name = "docker-runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker"

  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mode = "bridge"

  [runners.cache]
    Type = "s3"
    Shared = true
    [runners.cache.s3]
      ServerAddress = "s3.amazonaws.com"
      BucketName = "gitlab-runner-cache"
      BucketLocation = "us-east-1"
```

### Docker-in-Docker (dind)

Для сборки Docker образов используйте Docker-in-Docker:

```yaml
build:
  image: docker:24-alpine
  services:
    - docker:24-dind
  variables:
    DOCKER_DRIVER: overlay2
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

### Подключение Services

Services - это дополнительные контейнеры (БД, кеш и т.д.):

```yaml
test:
  image: node:18-alpine
  services:
    - postgres:15-alpine
    - redis:7-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test_user
    POSTGRES_PASSWORD: test_password
    DATABASE_URL: postgresql://test_user:test_password@postgres:5432/test_db
    REDIS_URL: redis://redis:6379
  script:
    - npm test
```

### Volume Mounting

```yaml
job:
  image: alpine
  variables:
    DOCKER_VOLUMES: "/builds:/builds"
  script:
    - ls /builds
```

## ☸️ Kubernetes Executor

### Преимущества
- ✅ Автомасштабирование
- ✅ Эффективное использование ресурсов
- ✅ Нативная интеграция с K8s
- ✅ Поддержка node selectors, tolerations, affinity

### Конфигурация Runner

```toml
# /etc/gitlab-runner/config.toml
[[runners]]
  name = "kubernetes-runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "kubernetes"

  [runners.kubernetes]
    host = "https://kubernetes.default.svc"
    namespace = "gitlab-runner"
    privileged = false

    # Resource limits
    cpu_limit = "1"
    cpu_request = "500m"
    memory_limit = "1Gi"
    memory_request = "512Mi"
    service_cpu_limit = "1"
    service_cpu_request = "200m"
    service_memory_limit = "1Gi"
    service_memory_request = "256Mi"

    # Helper image
    helper_image = "gitlab/gitlab-runner-helper:latest"

    # Node selector
    [runners.kubernetes.node_selector]
      "kubernetes.io/arch" = "amd64"
      "workload" = "ci"

    # Tolerations
    [[runners.kubernetes.pod_tolerations]]
      key = "dedicated"
      operator = "Equal"
      value = "ci"
      effect = "NoSchedule"
```

### Использование в Pipeline

```yaml
job:
  image: node:18-alpine
  tags:
    - kubernetes
  variables:
    # Переопределение ресурсов для конкретного job
    KUBERNETES_MEMORY_REQUEST: "1Gi"
    KUBERNETES_MEMORY_LIMIT: "2Gi"
    KUBERNETES_CPU_REQUEST: "500m"
    KUBERNETES_CPU_LIMIT: "1000m"

    # Node selector
    KUBERNETES_NODE_SELECTOR_WORKLOAD: "ci-heavy"
  script:
    - npm run build
```

### Services в Kubernetes

```yaml
test:
  image: node:18
  tags:
    - kubernetes
  services:
    - name: postgres:15-alpine
      alias: postgres
  variables:
    POSTGRES_DB: test_db
    KUBERNETES_SERVICE_MEMORY_REQUEST: "512Mi"
    KUBERNETES_SERVICE_MEMORY_LIMIT: "1Gi"
  script:
    - npm test
```

## 🔥 Kaniko - Сборка образов без Docker

### Почему Kaniko?

Docker-in-Docker требует privileged режима, что небезопасно. Kaniko решает эту проблему.

### Преимущества Kaniko
- ✅ Не требует Docker daemon
- ✅ Безопасно (не нужен privileged)
- ✅ Работает в любом Kubernetes кластере
- ✅ Поддержка кеширования слоев
- ✅ Multi-stage builds

### Базовое использование

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:latest
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"${CI_REGISTRY}\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
```

### Kaniko с кешированием

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"${CI_REGISTRY}\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
        --cache=true
        --cache-repo=$CI_REGISTRY_IMAGE/cache
        --cache-ttl=24h
        --compressed-caching=false
```

### Kaniko флаги

```bash
# Основные флаги
--context         # Путь к контексту сборки
--dockerfile      # Путь к Dockerfile
--destination     # Куда пушить образ (можно несколько)

# Кеширование
--cache=true                    # Включить кеш
--cache-repo=<repo>             # Репозиторий для кеша
--cache-ttl=24h                 # TTL кеша
--compressed-caching=false      # Сжатие кеша

# Build args и labels
--build-arg KEY=VALUE           # Build аргументы
--label key=value               # Метки образа

# Оптимизация
--snapshot-mode=redo            # Режим снапшотов (time, redo)
--use-new-run                   # Новый RUN executor
--single-snapshot               # Один снапшот на stage

# Target
--target=<stage>                # Конкретный stage для multi-stage

# Verbosity
--verbosity=info                # debug, info, warn, error
```

## 🧪 Тестирование - Best Practices

### 1. Структура тестов

```
tests/
├── unit/           # Юнит-тесты
├── integration/    # Интеграционные тесты
├── e2e/           # End-to-end тесты
└── performance/   # Нагрузочные тесты
```

### 2. Coverage Requirements

```yaml
test:
  script:
    - npm test -- --coverage
    # Fail если coverage < 80%
    - npm test -- --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80,"statements":80}}'
```

### 3. Параллельное выполнение

```yaml
test:
  parallel:
    matrix:
      - NODE_VERSION: ['16', '18', '20']
        DATABASE: ['postgres', 'mysql']
```

### 4. Retry для flaky тестов

```yaml
test:
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

## 🔍 Линтеры - Best Practices

### JavaScript/TypeScript

```yaml
lint:js:
  script:
    # ESLint с автофиксом в отдельной ветке
    - npx eslint . --fix
    - git diff --exit-code || (git checkout -b eslint-fixes && git commit -am "Auto-fix ESLint issues" && git push)
```

### Python

```yaml
lint:python:
  script:
    - pip install black flake8 isort mypy pylint
    - black --check .
    - flake8 .
    - isort --check-only .
    - mypy .
    - pylint **/*.py
```

### Multi-language проект

```yaml
lint:
  parallel:
    matrix:
      - LANGUAGE: js
        COMMAND: "npm run lint"
      - LANGUAGE: python
        COMMAND: "flake8 ."
      - LANGUAGE: go
        COMMAND: "golangci-lint run"
```

## 📊 Репорты и артефакты

### JUnit отчеты

```yaml
test:
  script:
    - npm test -- --reporters=jest-junit
  artifacts:
    reports:
      junit: junit.xml
```

### Coverage отчеты

```yaml
test:
  script:
    - npm test -- --coverage
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

### Code Quality

```yaml
lint:
  script:
    - npx eslint . --format gitlab
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

## 🚀 Оптимизация Pipeline

### 1. Кеширование

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/
  policy: pull-push
```

### 2. Использование needs

```yaml
deploy:
  stage: deploy
  needs: ["build", "test:unit"]  # Не ждем все jobs стадии test
  script:
    - ./deploy.sh
```

### 3. Rules вместо only/except

```yaml
job:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
    - changes:
        - "src/**/*"
```

## 📚 Полезные ссылки

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [GitLab Runner Executors](https://docs.gitlab.com/runner/executors/)
