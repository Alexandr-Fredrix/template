# Single Repository Deployment Guide

## 📖 Обзор

Руководство по деплою Kubernetes приложений из одного репозитория с использованием:
1. **Kubeconfig** - классический подход с файлом конфигурации
2. **Kubernetes Runner** - выполнение jobs как pods в кластере

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│  SINGLE REPOSITORY                                          │
│  ├── src/                    # Исходный код                  │
│  ├── tests/                  # Тесты                         │
│  ├── Dockerfile              # Docker образ                  │
│  ├── helm-chart/             # Helm chart в том же репо      │
│  │   ├── Chart.yaml                                          │
│  │   ├── values.yaml                                         │
│  │   ├── values-staging.yaml                                 │
│  │   ├── values-production.yaml                              │
│  │   └── templates/                                          │
│  └── .gitlab-ci.yml          # CI/CD: lint → test → build   │
│                              #        → deploy в один этап   │
└─────────────────────────────────────────────────────────────┘
                           ↓
              ┌────────────────────────────┐
              │   Kubernetes Cluster       │
              │   ├── staging namespace    │
              │   └── production namespace │
              └────────────────────────────┘
```

## 🔧 Метод 1: Деплой через Kubeconfig

### Что такое Kubeconfig?

Kubeconfig - это файл конфигурации kubectl, содержащий:
- URL кластера
- Сертификаты или токены для аутентификации
- Контексты (кластер + пользователь + namespace)

### Получение Kubeconfig

#### Вариант 1: Из существующего кластера

```bash
# Локально на машине с kubectl
cat ~/.kube/config | base64 -w0

# Сохраните результат в GitLab CI/CD Variables
```

#### Вариант 2: Создание ServiceAccount для GitLab

```bash
# 1. Создать ServiceAccount
kubectl create serviceaccount gitlab-deploy -n kube-system

# 2. Создать ClusterRoleBinding
kubectl create clusterrolebinding gitlab-deploy-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:gitlab-deploy

# 3. Получить токен (Kubernetes 1.24+)
kubectl create token gitlab-deploy -n kube-system --duration=87600h

# 4. Получить CA certificate
kubectl get secret \
  $(kubectl get sa gitlab-deploy -n kube-system -o jsonpath='{.secrets[0].name}') \
  -n kube-system \
  -o jsonpath='{.data.ca\.crt}'

# 5. Создать kubeconfig файл
cat > kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://your-k8s-api:6443
    certificate-authority-data: <CA_CERT_BASE64>
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: gitlab-deploy
    namespace: default
  name: gitlab
current-context: gitlab
users:
- name: gitlab-deploy
  user:
    token: <TOKEN>
EOF

# 6. Кодировать в base64
cat kubeconfig.yaml | base64 -w0
```

### Настройка в GitLab

**Settings → CI/CD → Variables:**

| Variable | Value | Type | Protected | Masked |
|----------|-------|------|-----------|--------|
| `KUBE_CONFIG_STAGING` | `<base64_kubeconfig>` | Variable | ✅ | ✅ |
| `KUBE_CONFIG_PRODUCTION` | `<base64_kubeconfig>` | Variable | ✅ | ✅ |

**Или отдельные компоненты:**

| Variable | Value |
|----------|-------|
| `KUBE_URL` | `https://k8s.example.com` |
| `KUBE_TOKEN` | `eyJhbGc...` |
| `KUBE_CA_CERT` | `LS0tLS...` (base64) |

### Примеры использования в Pipeline

#### Пример 1: Из переменной целиком

```yaml
deploy:staging:
  image: alpine/helm:latest
  before_script:
    - mkdir -p ~/.kube
    - echo "$KUBE_CONFIG_STAGING" | base64 -d > ~/.kube/config
    - chmod 600 ~/.kube/config
  script:
    - kubectl cluster-info
    - helm upgrade --install myapp ./helm-chart
```

#### Пример 2: Создание kubeconfig вручную

```yaml
deploy:staging:
  image: bitnami/kubectl:latest
  before_script:
    - mkdir -p ~/.kube
    - |
      cat > ~/.kube/config <<EOF
      apiVersion: v1
      kind: Config
      clusters:
      - cluster:
          server: ${KUBE_URL}
          certificate-authority-data: ${KUBE_CA_CERT}
        name: kubernetes
      contexts:
      - context:
          cluster: kubernetes
          user: gitlab
        name: gitlab
      current-context: gitlab
      users:
      - name: gitlab
        user:
          token: ${KUBE_TOKEN}
      EOF
    - chmod 600 ~/.kube/config
```

#### Пример 3: Через kubectl config команды

```yaml
deploy:staging:
  before_script:
    - kubectl config set-cluster kubernetes --server="${KUBE_URL}"
    - kubectl config set clusters.kubernetes.certificate-authority-data "${KUBE_CA_CERT}"
    - kubectl config set-credentials gitlab --token="${KUBE_TOKEN}"
    - kubectl config set-context gitlab --cluster=kubernetes --user=gitlab
    - kubectl config use-context gitlab
```

#### Пример 4: Insecure (для dev окружений)

```yaml
deploy:dev:
  before_script:
    - kubectl config set-cluster kubernetes
        --server="${KUBE_URL}"
        --insecure-skip-tls-verify=true
    - kubectl config set-credentials gitlab --token="${KUBE_TOKEN}"
    - kubectl config set-context gitlab --cluster=kubernetes --user=gitlab
    - kubectl config use-context gitlab
```

## 🎯 Метод 2: Kubernetes Runner

### Что такое Kubernetes Runner?

GitLab Runner, установленный в Kubernetes кластере, который:
- Запускает каждый job как отдельный pod
- Автоматически масштабируется
- Имеет доступ к кластеру через ServiceAccount
- Не требует Docker daemon (используется Kaniko)

### Установка Kubernetes Runner

#### 1. Установка через Helm

```bash
# Добавить Helm репозиторий
helm repo add gitlab https://charts.gitlab.io
helm repo update

# Создать namespace
kubectl create namespace gitlab-runner

# Получить registration token из GitLab:
# Settings → CI/CD → Runners → New project runner

# Установить runner
helm install gitlab-runner gitlab/gitlab-runner \
  --namespace gitlab-runner \
  --set gitlabUrl=https://gitlab.com/ \
  --set runnerRegistrationToken="YOUR_TOKEN" \
  --set rbac.create=true \
  --set runners.privileged=false \
  --set runners.tags="kubernetes,k8s" \
  --set runners.runUntagged=false \
  --set runners.config='
[[runners]]
  [runners.kubernetes]
    namespace = "gitlab-runner"
    image = "alpine:latest"

    # Resource requests/limits по умолчанию
    cpu_request = "100m"
    cpu_limit = "1"
    memory_request = "128Mi"
    memory_limit = "512Mi"

    # Service account
    service_account = "gitlab-runner"

    # Node selector (опционально)
    [runners.kubernetes.node_selector]
      "workload" = "ci"
'
```

#### 2. Создать ServiceAccount с правами

```yaml
# gitlab-runner-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-runner
  namespace: gitlab-runner
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitlab-runner
rules:
  # Права для деплоя в разные namespaces
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gitlab-runner
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: gitlab-runner
subjects:
  - kind: ServiceAccount
    name: gitlab-runner
    namespace: gitlab-runner
```

```bash
kubectl apply -f gitlab-runner-rbac.yaml
```

### Использование в Pipeline

#### In-cluster деплой (runner в том же кластере)

```yaml
deploy:staging:
  image: alpine/helm:latest
  tags:
    - kubernetes  # Использовать K8s runner
  script:
    # Kubeconfig уже настроен автоматически!
    - kubectl get nodes
    - helm upgrade --install myapp ./helm-chart
        --namespace staging
        --create-namespace
```

#### С resource limits

```yaml
deploy:production:
  image: alpine/helm:latest
  tags:
    - kubernetes
  variables:
    # Настройка ресурсов для pod'а job'а
    KUBERNETES_MEMORY_REQUEST: "512Mi"
    KUBERNETES_MEMORY_LIMIT: "1Gi"
    KUBERNETES_CPU_REQUEST: "250m"
    KUBERNETES_CPU_LIMIT: "500m"
  script:
    - helm upgrade --install myapp ./helm-chart
```

#### С node selector

```yaml
build:
  image: gcr.io/kaniko-project/executor:latest
  tags:
    - kubernetes
  variables:
    # Запустить на определенных нодах
    KUBERNETES_NODE_SELECTOR_WORKLOAD: "ci-heavy"
    KUBERNETES_NODE_SELECTOR_DISKTYPE: "ssd"
```

## 📊 Сравнение методов

| Параметр | Kubeconfig | Kubernetes Runner |
|----------|------------|-------------------|
| **Простота настройки** | ⭐⭐⭐ Легко | ⭐⭐ Средне |
| **Безопасность** | ⭐⭐ Токены в переменных | ⭐⭐⭐ ServiceAccount |
| **Производительность** | ⭐⭐ Зависит от runner | ⭐⭐⭐ В кластере |
| **Стоимость** | ⭐⭐⭐ Нужен обычный runner | ⭐⭐ Нужен K8s кластер |
| **Масштабирование** | ⭐⭐ Ограничено runner | ⭐⭐⭐ Автоскейлинг |
| **Docker builds** | ⭐⭐⭐ Docker-in-Docker | ⭐⭐⭐ Kaniko (безопаснее) |

## 💡 Best Practices

### 1. Используйте отдельные ServiceAccounts

```yaml
# Staging ServiceAccount (ограниченные права)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-staging
  namespace: gitlab-runner
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gitlab-staging
  namespace: staging
subjects:
  - kind: ServiceAccount
    name: gitlab-staging
    namespace: gitlab-runner
roleRef:
  kind: ClusterRole
  name: edit  # Только staging namespace
  apiGroup: rbac.authorization.k8s.io
```

### 2. Версионируйте kubeconfig

```yaml
deploy:
  before_script:
    - echo "Using kubeconfig version ${KUBE_CONFIG_VERSION:-v1}"
    - echo "$KUBE_CONFIG_STAGING" | base64 -d > ~/.kube/config
```

### 3. Проверяйте подключение

```yaml
deploy:
  before_script:
    - kubectl cluster-info
    - kubectl version --short
    - kubectl auth can-i create deployments --namespace staging
```

### 4. Используйте --atomic для безопасности

```yaml
deploy:
  script:
    - helm upgrade --install myapp ./helm-chart
        --atomic  # Автооткат при ошибке
        --wait
        --timeout 5m
```

### 5. Логируйте изменения

```yaml
deploy:
  before_script:
    - helm diff upgrade myapp ./helm-chart || true
  script:
    - helm upgrade --install myapp ./helm-chart
  after_script:
    - helm history myapp
```

## 🔍 Отладка

### Проверка kubeconfig

```bash
# Декодировать и проверить
echo "$KUBE_CONFIG_STAGING" | base64 -d | grep server

# Проверить доступ
kubectl --kubeconfig=./config.yaml get nodes
```

### Проверка ServiceAccount

```bash
# Получить токен SA
kubectl get secret -n gitlab-runner \
  $(kubectl get sa gitlab-runner -n gitlab-runner -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{.data.token}' | base64 -d

# Проверить права
kubectl auth can-i create deployments --as=system:serviceaccount:gitlab-runner:gitlab-runner
```

### Debug в pipeline

```yaml
debug:kubeconfig:
  script:
    - cat ~/.kube/config | grep server
    - kubectl config view
    - kubectl config current-context
    - kubectl auth can-i '*' '*' --all-namespaces
```

## 📚 Примеры реальных сценариев

### Сценарий 1: Feature branch → Review app

```yaml
deploy:review:
  image: alpine/helm:latest
  tags:
    - kubernetes
  script:
    - export REVIEW_NAMESPACE="review-${CI_COMMIT_REF_SLUG}"
    - helm upgrade --install myapp-${CI_COMMIT_REF_SLUG} ./helm-chart
        --namespace ${REVIEW_NAMESPACE}
        --create-namespace
        --set ingress.hosts[0].host=${CI_COMMIT_REF_SLUG}.review.example.com
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://${CI_COMMIT_REF_SLUG}.review.example.com
    on_stop: stop:review
  only:
    - branches
  except:
    - main

stop:review:
  script:
    - helm uninstall myapp-${CI_COMMIT_REF_SLUG} -n review-${CI_COMMIT_REF_SLUG}
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

### Сценарий 2: Multi-cluster деплой

```yaml
.deploy_template: &deploy_template
  image: alpine/helm:latest
  script:
    - mkdir -p ~/.kube
    - echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config
    - helm upgrade --install myapp ./helm-chart

deploy:us-east:
  <<: *deploy_template
  variables:
    KUBE_CONFIG: $KUBE_CONFIG_US_EAST
  environment:
    name: production/us-east

deploy:eu-west:
  <<: *deploy_template
  variables:
    KUBE_CONFIG: $KUBE_CONFIG_EU_WEST
  environment:
    name: production/eu-west
```

## 📖 Полезные ссылки

- [GitLab Kubernetes Integration](https://docs.gitlab.com/ee/user/project/clusters/deploy_to_cluster.html)
- [GitLab Runner Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html)
- [Kubectl Configuration](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
