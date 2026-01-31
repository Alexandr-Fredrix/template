# GitLab CI/CD - Руководство и Шаблоны

## 📖 Что такое GitLab CI/CD?

GitLab CI/CD - это встроенная система непрерывной интеграции и доставки в GitLab. Pipeline описывается в файле `.gitlab-ci.yml` в корне репозитория.

## 🏗️ Базовая структура .gitlab-ci.yml

```yaml
# Стадии pipeline
stages:
  - build
  - test
  - deploy

# Переменные
variables:
  DOCKER_DRIVER: overlay2

# Job сборки
build-job:
  stage: build
  script:
    - echo "Building the app"
    - npm install
    - npm run build
  artifacts:
    paths:
      - dist/

# Job тестирования
test-job:
  stage: test
  script:
    - npm test
  coverage: '/Coverage: \d+\.\d+/'

# Job деплоя
deploy-job:
  stage: deploy
  script:
    - echo "Deploying application"
  only:
    - main
```

## 📋 Основные концепции

### Stages (Стадии)
```yaml
stages:
  - build        # Сборка
  - test         # Тестирование
  - security     # Проверка безопасности
  - deploy       # Деплой
  - cleanup      # Очистка
```

### Jobs (Задачи)
```yaml
job-name:
  stage: build
  image: node:18        # Docker образ
  services:             # Дополнительные сервисы
    - docker:dind
  before_script:        # Выполняется перед script
    - npm install
  script:               # Основные команды
    - npm run build
  after_script:         # Выполняется после script
    - echo "Done"
  artifacts:            # Артефакты для следующих стадий
    paths:
      - dist/
  cache:                # Кеширование
    paths:
      - node_modules/
  only:                 # Условия выполнения
    - main
  except:               # Исключения
    - tags
  tags:                 # Теги runner'ов
    - docker
  when: on_success      # manual, on_failure, always
  allow_failure: false  # Разрешить падение
  retry: 2              # Количество повторов
```

### Variables (Переменные)
```yaml
# Глобальные переменные
variables:
  POSTGRES_DB: test_db
  CI_DEBUG_TRACE: "false"

# Переменные job
job-name:
  variables:
    DEPLOY_ENV: production
  script:
    - echo $DEPLOY_ENV
```

### Artifacts (Артефакты)
```yaml
build:
  artifacts:
    name: "build-$CI_COMMIT_REF_NAME"
    paths:
      - dist/
      - build/
    exclude:
      - dist/*.map
    expire_in: 1 week
    when: on_success
    reports:
      junit: test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

### Cache (Кеширование)
```yaml
# Глобальный кеш
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/

# Кеш job
build:
  cache:
    key: build-cache
    paths:
      - vendor/
    policy: pull-push  # pull, push
```

## 🎯 Расширенные возможности

### Include (Переиспользование)
```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - remote: 'https://example.com/ci/template.yml'
  - template: Security/SAST.gitlab-ci.yml
```

### Extends (Наследование)
```yaml
.deploy_template:
  stage: deploy
  script:
    - echo "Deploying"
  only:
    - main

deploy_production:
  extends: .deploy_template
  environment:
    name: production
    url: https://prod.example.com

deploy_staging:
  extends: .deploy_template
  environment:
    name: staging
    url: https://staging.example.com
```

### Rules (Правила выполнения)
```yaml
job:
  script: echo "Hello"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: always
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual
    - if: '$CI_COMMIT_TAG'
      when: never
    - changes:
        - Dockerfile
        - docker-compose.yml
      when: on_success
```

### Needs (Зависимости между jobs)
```yaml
# Ускоряет pipeline, не дожидаясь всех jobs стадии

build:
  stage: build
  script: make build

test:unit:
  stage: test
  needs: [build]
  script: make test

test:integration:
  stage: test
  needs: [build]
  script: make integration-test

deploy:
  stage: deploy
  needs: [test:unit, test:integration]
  script: make deploy
```

### Parallel (Параллельное выполнение)
```yaml
test:
  script: npm test
  parallel:
    matrix:
      - NODE_VERSION: ['14', '16', '18']
        DATABASE: ['postgres', 'mysql']

# Создаст 6 jobs:
# test: [14, postgres]
# test: [14, mysql]
# test: [16, postgres]
# ...
```

## 💡 Best Practices

### 1. Используйте templates
Создайте `.gitlab/ci/templates/`:
```yaml
# .gitlab/ci/templates/build.yml
.build_template:
  stage: build
  before_script:
    - echo "Setting up build environment"
  script:
    - echo "Building"
  tags:
    - docker
```

### 2. Версионируйте Docker образы
```yaml
variables:
  DOCKER_IMAGE: registry.gitlab.com/$CI_PROJECT_PATH
  DOCKER_TAG: $CI_COMMIT_REF_SLUG-$CI_COMMIT_SHORT_SHA

build:
  script:
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    - docker push $DOCKER_IMAGE:$DOCKER_TAG
```

### 3. Используйте environments
```yaml
deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
    on_stop: stop_production
    auto_stop_in: 1 week

stop_production:
  stage: deploy
  environment:
    name: production
    action: stop
  when: manual
```

### 4. Настройте retry и timeout
```yaml
test:
  script: npm test
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
  timeout: 30m
```

### 5. Используйте anchors для DRY
```yaml
.common: &common
  image: node:18
  before_script:
    - npm install

build:
  <<: *common
  script:
    - npm run build

test:
  <<: *common
  script:
    - npm test
```

## 🔒 Безопасность

### Protected Variables
В Settings > CI/CD > Variables создайте защищенные переменные:
- `API_KEY`
- `DATABASE_PASSWORD`
- `AWS_ACCESS_KEY_ID`

```yaml
deploy:
  script:
    - deploy.sh --api-key $API_KEY
  only:
    - main
```

### Secrets Management
```yaml
# Используйте Vault или подобные решения
deploy:
  script:
    - export SECRET=$(vault read secret/data/myapp)
    - deploy.sh
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
```

## 📊 Monitoring и Reporting

### Coverage
```yaml
test:
  script:
    - npm test -- --coverage
  coverage: '/^Statements\s+:\s+(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

### Test Reports
```yaml
test:
  script:
    - npm test -- --ci --reporters=default --reporters=jest-junit
  artifacts:
    reports:
      junit: junit.xml
```

## 🔍 Отладка

```yaml
# Включить debug режим
variables:
  CI_DEBUG_TRACE: "true"

# Сохранить логи как артефакты
job:
  after_script:
    - cat /var/log/app.log > logs.txt
  artifacts:
    when: on_failure
    paths:
      - logs.txt
```

## 📚 Полезные переменные CI/CD

```yaml
script:
  - echo "Project: $CI_PROJECT_NAME"
  - echo "Branch: $CI_COMMIT_BRANCH"
  - echo "Tag: $CI_COMMIT_TAG"
  - echo "SHA: $CI_COMMIT_SHA"
  - echo "Short SHA: $CI_COMMIT_SHORT_SHA"
  - echo "Registry: $CI_REGISTRY"
  - echo "Job ID: $CI_JOB_ID"
  - echo "Pipeline ID: $CI_PIPELINE_ID"
```

## 📖 Документация

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [.gitlab-ci.yml Reference](https://docs.gitlab.com/ee/ci/yaml/)
- [CI/CD Examples](https://docs.gitlab.com/ee/ci/examples/)
