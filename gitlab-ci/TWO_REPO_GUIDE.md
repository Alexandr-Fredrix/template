# GitOps - Двухрепозиторная архитектура

## 📖 Концепция

Разделение кода приложения и инфраструктурной конфигурации на два репозитория - это best practice для GitOps.

### Преимущества

✅ **Разделение ответственности** - разработчики работают с кодом, DevOps с инфраструктурой
✅ **Безопасность** - разные уровни доступа к репозиториям
✅ **История изменений** - четкая история деплоев
✅ **Откат** - легко откатить конфигурацию независимо от кода
✅ **Code review** - отдельный review инфраструктурных изменений

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│  APP REPOSITORY (your-app)                                  │
│  ├── src/                    # Исходный код                  │
│  ├── tests/                  # Тесты                         │
│  ├── Dockerfile              # Docker образ                  │
│  └── .gitlab-ci.yml          # CI: lint → test → build       │
│                              #     → push → trigger           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Trigger / Update
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  INFRA REPOSITORY (infrastructure)                          │
│  ├── helm-charts/            # Helm charts                   │
│  │   └── myapp/             # Chart приложения               │
│  │       ├── Chart.yaml                                      │
│  │       ├── values.yaml                                     │
│  │       ├── values-staging.yaml                             │
│  │       ├── values-production.yaml                          │
│  │       └── templates/                                      │
│  └── .gitlab-ci.yml          # CD: validate → deploy         │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Настройка

### Шаг 1: Создать Access Token для infra репозитория

В **infra repository** → Settings → Access Tokens:
- Name: `app-repo-token`
- Role: `Developer` или `Maintainer`
- Scopes: `api`, `write_repository`

Сохраните токен: `glpat-xxxxxxxxxxxxxxxxxxxx`

### Шаг 2: Добавить переменные в app репозиторий

В **app repository** → Settings → CI/CD → Variables:

| Variable | Value | Protected | Masked |
|----------|-------|-----------|--------|
| `INFRA_ACCESS_TOKEN` | `glpat-xxxxx` | ✅ | ✅ |
| `INFRA_PROJECT_ID` | `123456` | ✅ | - |
| `SLACK_WEBHOOK_URL` | `https://hooks.slack.com/...` | - | ✅ |

### Шаг 3: Настроить Pipeline Trigger в infra репозитории

В **infra repository** → Settings → CI/CD → Pipeline triggers:
- Description: `Triggered by app-repo`
- Сохраните token: `trigger_token_xxxxx`

Добавьте в **app repository** переменную:
- `INFRA_TRIGGER_TOKEN` = `trigger_token_xxxxx`

### Шаг 4: Настроить Kubernetes доступ

В **infra repository** → Settings → CI/CD → Variables:

**Для Staging:**
| Variable | Value |
|----------|-------|
| `KUBE_STAGING_URL` | `https://k8s-staging.example.com` |
| `KUBE_STAGING_TOKEN` | `k8s-sa-token-xxxxx` |

**Для Production:**
| Variable | Value |
|----------|-------|
| `KUBE_PROD_URL` | `https://k8s-prod.example.com` |
| `KUBE_PROD_TOKEN` | `k8s-sa-token-yyyyy` |

## 📋 Структура файлов

### App Repository

```
app-repository/
├── src/
├── tests/
├── Dockerfile
├── package.json
├── .gitlab-ci.yml           # ← app-repository.yml
└── README.md
```

### Infra Repository

```
infra-repository/
├── helm-charts/
│   └── myapp/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-staging.yaml
│       ├── values-production.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
├── .gitlab-ci.yml           # ← infra-repository.yml
├── .yamllint.yml
└── README.md
```

## 🔄 Workflow - Как это работает

### Вариант 1: Через Git Commit (рекомендуется для production)

```mermaid
sequenceDiagram
    Developer->>App Repo: git push
    App Repo->>App Repo: lint, test, build
    App Repo->>Container Registry: push image:abc123
    App Repo->>Infra Repo: git commit (update image tag)
    Infra Repo->>Infra Repo: trigger pipeline
    Infra Repo->>Kubernetes: helm upgrade
```

**Преимущества:**
- ✅ Полная история изменений в Git
- ✅ Code review для деплоев
- ✅ GitOps принцип
- ✅ Легкий откат через Git

**Пример:**

```yaml
# В app-repository.yml
update-infra:git-commit:
  script:
    - git clone https://oauth2:${INFRA_ACCESS_TOKEN}@gitlab.com/group/infra-repo.git
    - cd infra-repo
    - sed -i "s|tag:.*|tag: ${IMAGE_TAG}|g" helm-charts/myapp/values-staging.yaml
    - git commit -am "Update image to ${IMAGE_TAG}"
    - git push origin main
```

### Вариант 2: Через Pipeline Trigger (быстрый деплой)

```mermaid
sequenceDiagram
    Developer->>App Repo: git push
    App Repo->>App Repo: lint, test, build
    App Repo->>Container Registry: push image:abc123
    App Repo->>Infra Repo: trigger pipeline (API call)
    Infra Repo->>Kubernetes: helm upgrade --set image.tag=abc123
```

**Преимущества:**
- ✅ Быстро
- ✅ Автоматизация
- ✅ Параметризация через переменные

**Пример:**

```yaml
# В app-repository.yml
trigger-deploy:staging:
  script:
    - curl -X POST
        -F "token=${CI_JOB_TOKEN}"
        -F "ref=main"
        -F "variables[IMAGE_TAG]=${IMAGE_TAG}"
        "https://gitlab.com/api/v4/projects/${INFRA_PROJECT_ID}/trigger/pipeline"
```

### Вариант 3: Downstream Pipeline (лучшая интеграция)

```yaml
# В app-repository.yml
trigger-deploy:downstream:
  trigger:
    project: group/infra-repo
    branch: main
    strategy: depend
  variables:
    IMAGE_TAG: $IMAGE_TAG
    APP_NAME: myapp
```

**Преимущества:**
- ✅ Нативная интеграция GitLab
- ✅ Визуализация в UI
- ✅ Передача артефактов
- ✅ Зависимые pipelines

## 💡 Практические примеры

### Пример 1: Деплой в staging после merge в develop

**App repo:**
```yaml
build:docker:
  only:
    - develop
  script:
    - docker build -t $IMAGE:$TAG .
    - docker push $IMAGE:$TAG

trigger-staging:
  only:
    - develop
  trigger:
    project: group/infra-repo
    branch: main
  variables:
    ENVIRONMENT: staging
    IMAGE_TAG: $CI_COMMIT_SHORT_SHA
```

**Infra repo:**
```yaml
deploy:staging:
  only:
    variables:
      - $ENVIRONMENT == "staging"
  script:
    - helm upgrade myapp ./helm-charts/myapp
        -f values-staging.yaml
        --set image.tag=$IMAGE_TAG
```

### Пример 2: Production деплой с подтверждением

**App repo:**
```yaml
trigger-production:
  only:
    - main
  when: manual
  trigger:
    project: group/infra-repo
  variables:
    ENVIRONMENT: production
    IMAGE_TAG: $CI_COMMIT_TAG
```

**Infra repo:**
```yaml
deploy:production:
  only:
    variables:
      - $ENVIRONMENT == "production"
  when: manual
  script:
    - helm upgrade myapp ./helm-charts/myapp
        -f values-production.yaml
        --set image.tag=$IMAGE_TAG
        --atomic
```

### Пример 3: Обновление нескольких окружений

**App repo:**
```yaml
.trigger_template: &trigger_deploy
  trigger:
    project: group/infra-repo
    branch: main
  variables:
    IMAGE_TAG: $CI_COMMIT_SHORT_SHA

deploy:dev:
  <<: *trigger_deploy
  variables:
    ENVIRONMENT: dev
  only:
    - develop

deploy:staging:
  <<: *trigger_deploy
  variables:
    ENVIRONMENT: staging
  only:
    - main
  when: manual

deploy:production:
  <<: *trigger_deploy
  variables:
    ENVIRONMENT: production
  only:
    - tags
  when: manual
```

## 🔍 Отладка

### Проверить что image существует

```yaml
verify:image:
  stage: deploy-trigger
  image: docker:24
  script:
    - docker pull $IMAGE_NAME:$IMAGE_TAG
  only:
    - main
```

### Просмотр переданных переменных

```yaml
# В infra repo
debug:variables:
  script:
    - echo "Environment: $ENVIRONMENT"
    - echo "App Name: $APP_NAME"
    - echo "Image Tag: $IMAGE_TAG"
    - echo "Triggered by: $TRIGGERED_BY"
```

### Dry-run деплоя

```yaml
plan:staging:
  script:
    - helm upgrade --install myapp ./helm-charts/myapp
        --dry-run
        --debug
        -f values-staging.yaml
        --set image.tag=$IMAGE_TAG
```

## 🎯 Best Practices

### 1. Всегда используйте конкретные теги образов

❌ **Плохо:**
```yaml
image:
  tag: latest
```

✅ **Хорошо:**
```yaml
image:
  tag: {{ .Values.imageTag }}  # Передается из pipeline
```

### 2. Валидация перед деплоем

```yaml
validate:
  before_script:
    - helm lint ./helm-charts/myapp
    - kubectl apply --dry-run=server -f manifests/
```

### 3. Используйте --atomic для безопасного деплоя

```yaml
deploy:
  script:
    - helm upgrade --install myapp ./chart
        --atomic
        --timeout 5m
```

### 4. Включите нотификации

```yaml
notify:slack:
  when: always
  script:
    - curl -X POST $SLACK_WEBHOOK_URL
        -d '{"text":"Deploy '$ENVIRONMENT' - '$CI_JOB_STATUS'"}'
```

### 5. Храните историю деплоев

```yaml
deploy:production:
  artifacts:
    paths:
      - deploy-info.json
    expire_in: 30 days
  script:
    - echo '{"image":"'$IMAGE_TAG'","date":"'$(date)'"}' > deploy-info.json
```

## 📊 Мониторинг

### Создание dashboard для деплоев

```yaml
# .gitlab-ci.yml в infra repo
report:deployment-metrics:
  script:
    - |
      curl -X POST $PROMETHEUS_PUSHGATEWAY/metrics/job/gitlab-deploy \
        -d "gitlab_deploy_info{environment=\"$ENVIRONMENT\",app=\"$APP_NAME\",image_tag=\"$IMAGE_TAG\"} 1"
```

## 🔒 Безопасность

### 1. Ограничение доступа

- **App repo:** Разработчики имеют `Developer` доступ
- **Infra repo:** Только DevOps/SRE имеют `Maintainer` доступ

### 2. Protected branches

В **infra repository:**
- `main` branch → Protected
- Require merge request approval
- Allow force push: Disabled

### 3. Secrets management

```yaml
# Используйте External Secrets
deploy:
  script:
    - helm upgrade myapp ./chart
        --set-file secrets.yaml=<(kubectl get secret myapp-secrets -o yaml)
```

## 📚 Полезные ссылки

- [GitLab Multi-project pipelines](https://docs.gitlab.com/ee/ci/pipelines/multi_project_pipelines.html)
- [GitLab Trigger tokens](https://docs.gitlab.com/ee/ci/triggers/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [GitOps Principles](https://www.gitops.tech/)
