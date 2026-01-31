# Примеры структуры файлов для двухрепозиторной архитектуры

## 📁 App Repository - Полная структура

```
my-application/
├── .gitlab-ci.yml                  # ← Скопируйте app-repository.yml
├── .gitignore
├── package.json
├── package-lock.json
├── .eslintrc.json
├── .prettierrc
├── jest.config.js
├── Dockerfile
├── .dockerignore
│
├── src/
│   ├── index.ts
│   ├── app.ts
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   └── models/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── README.md
```

### .gitlab-ci.yml для App репозитория

```yaml
# Минимальная версия
stages:
  - lint
  - test
  - build
  - deploy-trigger

variables:
  IMAGE_NAME: $CI_REGISTRY_IMAGE
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA
  INFRA_PROJECT_ID: "123456"

lint:
  stage: lint
  image: node:18-alpine
  script:
    - npm ci
    - npm run lint

test:
  stage: test
  image: node:18-alpine
  script:
    - npm ci
    - npm test

build:
  stage: build
  image: docker:24-alpine
  services:
    - docker:24-dind
  script:
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - docker push $IMAGE_NAME:$IMAGE_TAG
  only:
    - main
    - develop

# Вариант 1: Trigger через API
trigger-deploy:
  stage: deploy-trigger
  image: curlimages/curl:latest
  script:
    - |
      curl -X POST \
        -F "token=${INFRA_TRIGGER_TOKEN}" \
        -F "ref=main" \
        -F "variables[ENVIRONMENT]=${CI_COMMIT_REF_SLUG}" \
        -F "variables[IMAGE_TAG]=${IMAGE_TAG}" \
        "https://gitlab.com/api/v4/projects/${INFRA_PROJECT_ID}/trigger/pipeline"
  only:
    - main
    - develop
  when: manual

# Вариант 2: Downstream pipeline (рекомендуется)
trigger-deploy-downstream:
  stage: deploy-trigger
  trigger:
    project: your-group/infrastructure
    branch: main
  variables:
    ENVIRONMENT: $CI_COMMIT_REF_SLUG
    IMAGE_TAG: $IMAGE_TAG
  only:
    - main
    - develop
  when: manual
```

## 📁 Infrastructure Repository - Полная структура

```
infrastructure/
├── .gitlab-ci.yml                  # ← Скопируйте infra-repository.yml
├── .yamllint.yml
├── .gitignore
│
├── helm-charts/
│   ├── myapp/
│   │   ├── Chart.yaml
│   │   ├── values.yaml             # Базовые значения
│   │   ├── values-staging.yaml     # Staging override
│   │   ├── values-production.yaml  # Production override
│   │   ├── .helmignore
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── configmap.yaml
│   │       ├── secret.yaml
│   │       ├── hpa.yaml
│   │       └── serviceaccount.yaml
│   │
│   └── another-app/
│       └── ...
│
├── smoke-tests/
│   ├── collection.json             # Postman коллекция
│   ├── postman-staging.json
│   └── postman-production.json
│
└── README.md
```

### Chart.yaml

```yaml
apiVersion: v2
name: myapp
description: My Application Helm Chart
type: application
version: 1.0.0
appVersion: "1.0"
```

### values.yaml (базовые значения)

```yaml
# Образ приложения
image:
  repository: registry.gitlab.com/your-group/my-application
  pullPolicy: IfNotPresent
  tag: "latest"  # Будет переопределен из pipeline

replicaCount: 2

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### values-staging.yaml

```yaml
# Override для staging
replicaCount: 1

image:
  tag: develop  # Переопределяется из pipeline

ingress:
  hosts:
    - host: staging.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false

environment: staging
```

### values-production.yaml

```yaml
# Override для production
replicaCount: 3

image:
  tag: main  # Переопределяется из pipeline

ingress:
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: example-com-tls
      hosts:
        - example.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20

environment: production
```

### .gitlab-ci.yml для Infra репозитория

```yaml
# Минимальная версия
stages:
  - validate
  - deploy

variables:
  APP_NAME: "${APP_NAME:-myapp}"
  ENVIRONMENT: "${ENVIRONMENT:-staging}"
  IMAGE_TAG: "${IMAGE_TAG:-latest}"

validate:
  stage: validate
  image: alpine/helm:latest
  script:
    - helm lint helm-charts/${APP_NAME}/

deploy:staging:
  stage: deploy
  image: alpine/helm:latest
  before_script:
    - kubectl config set-cluster k8s --server="${KUBE_STAGING_URL}"
    - kubectl config set-credentials admin --token="${KUBE_STAGING_TOKEN}"
    - kubectl config set-context default --cluster=k8s --user=admin
    - kubectl config use-context default
  script:
    - helm upgrade --install ${APP_NAME} helm-charts/${APP_NAME}/
        --namespace staging
        --create-namespace
        --values helm-charts/${APP_NAME}/values-staging.yaml
        --set image.tag=${IMAGE_TAG}
        --wait
        --timeout 5m
  environment:
    name: staging
    url: https://staging.example.com
  only:
    variables:
      - $ENVIRONMENT == "staging"
  when: manual

deploy:production:
  stage: deploy
  image: alpine/helm:latest
  before_script:
    - kubectl config set-cluster k8s --server="${KUBE_PROD_URL}"
    - kubectl config set-credentials admin --token="${KUBE_PROD_TOKEN}"
    - kubectl config set-context default --cluster=k8s --user=admin
    - kubectl config use-context default
  script:
    - helm upgrade --install ${APP_NAME} helm-charts/${APP_NAME}/
        --namespace production
        --create-namespace
        --values helm-charts/${APP_NAME}/values-production.yaml
        --set image.tag=${IMAGE_TAG}
        --wait
        --timeout 10m
        --atomic
  environment:
    name: production
    url: https://example.com
  only:
    variables:
      - $ENVIRONMENT == "production"
  when: manual
```

## 🚀 Быстрый старт

### 1. Создание репозиториев

```bash
# App репозиторий
mkdir my-application
cd my-application
git init
# Скопируйте app-repository.yml как .gitlab-ci.yml
# Добавьте ваш код

# Infra репозиторий
mkdir infrastructure
cd infrastructure
git init
# Скопируйте infra-repository.yml как .gitlab-ci.yml
# Создайте Helm charts
```

### 2. Настройка переменных

**App repository → Settings → CI/CD → Variables:**

```bash
INFRA_PROJECT_ID = "123456"  # ID infra репозитория
INFRA_TRIGGER_TOKEN = "trigger_token_xxxxx"
INFRA_ACCESS_TOKEN = "glpat-xxxxx"  # Для git commit метода
```

**Infra repository → Settings → CI/CD → Variables:**

```bash
# Staging
KUBE_STAGING_URL = "https://k8s-staging.example.com"
KUBE_STAGING_TOKEN = "k8s-sa-token-xxxxx"

# Production
KUBE_PROD_URL = "https://k8s-prod.example.com"
KUBE_PROD_TOKEN = "k8s-sa-token-yyyyy"
```

### 3. Первый деплой

```bash
# 1. Commit в app репозиторий
cd my-application
git add .
git commit -m "Initial commit"
git push

# 2. Pipeline автоматически:
#    - Запустит линтеры
#    - Выполнит тесты
#    - Соберет Docker образ
#    - Запушит в registry

# 3. Вручную запустить trigger-deploy job

# 4. Infra pipeline автоматически:
#    - Валидирует Helm chart
#    - Деплоит в Kubernetes
```

## 📝 Примеры команд

### Проверка образа

```bash
# В app репозитории после build
docker pull registry.gitlab.com/your-group/my-application:abc123
```

### Локальный Helm test

```bash
# В infra репозитории
cd helm-charts/myapp

# Dry-run
helm install myapp . --dry-run --debug \
  -f values-staging.yaml \
  --set image.tag=abc123

# Template
helm template myapp . \
  -f values-staging.yaml \
  --set image.tag=abc123
```

### Проверка деплоя

```bash
# После деплоя
kubectl get pods -n staging
kubectl get svc -n staging
kubectl get ingress -n staging

# Логи
kubectl logs -n staging -l app.kubernetes.io/name=myapp
```

## 🔄 Workflow примеры

### Feature branch → Staging

```bash
# 1. Создать feature branch
git checkout -b feature/new-feature

# 2. Разработка
# ... код ...

# 3. Commit и push
git push origin feature/new-feature

# 4. Создать Merge Request

# 5. После approval и merge в develop:
#    - Автоматически билдится образ
#    - Вручную триггерим деплой в staging
```

### Staging → Production

```bash
# 1. Merge develop → main
git checkout main
git merge develop
git push

# 2. Создать tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push --tags

# 3. Pipeline:
#    - Билдит образ с тегом v1.0.0
#    - Вручную триггерим деплой в production
```

### Hotfix в production

```bash
# 1. Создать hotfix branch от main
git checkout -b hotfix/critical-fix main

# 2. Фикс
# ... код ...

# 3. Commit, push, merge в main

# 4. Tag
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push --tags

# 5. Деплой в production через pipeline
```

## 💡 Tips & Tricks

### 1. Автоматический деплой в staging

```yaml
# В app-repository.yml
trigger-deploy:staging:
  only:
    - develop
  when: on_success  # Автоматически после успешного build
```

### 2. Rollback скрипт

```bash
#!/bin/bash
# rollback.sh

APP_NAME="myapp"
NAMESPACE="production"

# Получить предыдущую версию
PREVIOUS_REVISION=$(helm history $APP_NAME -n $NAMESPACE -o json | jq -r '.[1].revision')

# Откат
helm rollback $APP_NAME $PREVIOUS_REVISION -n $NAMESPACE

echo "Rolled back to revision $PREVIOUS_REVISION"
```

### 3. Мультиокружение в одном pipeline

```yaml
# В infra-repository.yml
.deploy_template: &deploy_template
  image: alpine/helm:latest
  script:
    - helm upgrade --install ${APP_NAME} helm-charts/${APP_NAME}/
        -f helm-charts/${APP_NAME}/values-${ENVIRONMENT}.yaml
        --set image.tag=${IMAGE_TAG}

deploy:dev:
  <<: *deploy_template
  variables:
    ENVIRONMENT: dev

deploy:staging:
  <<: *deploy_template
  variables:
    ENVIRONMENT: staging

deploy:production:
  <<: *deploy_template
  variables:
    ENVIRONMENT: production
```

## 📚 Дополнительные ресурсы

- [GitLab Multi-project Pipelines](https://docs.gitlab.com/ee/ci/pipelines/multi_project_pipelines.html)
- [Helm Chart Development](https://helm.sh/docs/chart_template_guide/)
- [GitOps Workflow](https://www.weave.works/technologies/gitops/)
