# ArgoCD - GitOps Руководство и Шаблоны

## 📖 Что такое ArgoCD?

ArgoCD - это декларативный инструмент непрерывной доставки для Kubernetes, следующий принципам GitOps. Он автоматически синхронизирует состояние приложений в кластере с конфигурацией, хранящейся в Git репозитории.

## 🏗️ Основные концепции

### Application
Приложение в ArgoCD - это комбинация источника (Git репозиторий) и назначения (Kubernetes кластер и namespace).

### GitOps принципы
1. **Git как единственный источник правды** - вся конфигурация в Git
2. **Декларативность** - описание желаемого состояния
3. **Автоматическая синхронизация** - ArgoCD приводит кластер к желаемому состоянию
4. **Иммутабельность** - изменения только через Git

## 🎯 Установка ArgoCD

```bash
# Создать namespace
kubectl create namespace argocd

# Установить ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Проверить установку
kubectl get pods -n argocd

# Получить admin пароль
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward для доступа к UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Логин в CLI
argocd login localhost:8080

# Изменить пароль
argocd account update-password
```

## 📋 Основные команды ArgoCD CLI

```bash
# Добавить кластер
argocd cluster add my-cluster

# Создать приложение
argocd app create myapp \
  --repo https://github.com/user/repo.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Список приложений
argocd app list

# Информация о приложении
argocd app get myapp

# Синхронизировать приложение
argocd app sync myapp

# Автосинхронизация
argocd app set myapp --sync-policy automated

# Удалить приложение
argocd app delete myapp

# История синхронизаций
argocd app history myapp

# Rollback
argocd app rollback myapp 1

# Diff
argocd app diff myapp

# Logs
argocd app logs myapp

# Добавить репозиторий
argocd repo add https://github.com/user/repo.git \
  --username user \
  --password token

# Список репозиториев
argocd repo list
```

## 💡 Application Manifest

### Базовый пример
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  # Источник (Git репозиторий)
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: HEAD
    path: manifests

  # Назначение (кластер и namespace)
  destination:
    server: https://kubernetes.default.svc
    namespace: default

  # Политика синхронизации
  syncPolicy:
    automated:
      prune: true        # Удалять ресурсы, которых нет в Git
      selfHeal: true     # Автоматически исправлять дрифт
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### С Helm
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-helm
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: HEAD
    path: helm-chart
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
      parameters:
        - name: image.tag
          value: v1.2.3
        - name: replicaCount
          value: "3"
      releaseName: myapp

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### С Kustomize
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-kustomize
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: HEAD
    path: overlays/production
    kustomize:
      namePrefix: prod-
      nameSuffix: -v1
      images:
        - name: myapp
          newTag: v1.2.3
      commonLabels:
        environment: production

  destination:
    server: https://kubernetes.default.svc
    namespace: production
```

## 🔧 App of Apps Pattern

Управление множеством приложений:

```yaml
# apps/root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: HEAD
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```yaml
# apps/frontend-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/repo.git
    path: services/frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 🚀 Многокластерное развертывание

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-app
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - cluster: production-us
        url: https://prod-us-cluster
      - cluster: production-eu
        url: https://prod-eu-cluster
      - cluster: staging
        url: https://staging-cluster

  template:
    metadata:
      name: '{{cluster}}-myapp'
    spec:
      source:
        repoURL: https://github.com/user/repo.git
        targetRevision: HEAD
        path: manifests
        helm:
          valueFiles:
            - values-{{cluster}}.yaml
      destination:
        server: '{{url}}'
        namespace: myapp
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## 🔒 Безопасность

### RBAC
```yaml
# argocd-rbac-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    # Developers - только чтение
    p, role:developers, applications, get, */*, allow
    p, role:developers, repositories, get, *, allow

    # Operators - sync и rollback
    p, role:operators, applications, *, */*, allow
    p, role:operators, applications, delete, */*, deny

    # Admins - полный доступ
    p, role:admin, *, *, *, allow

    # Привязки
    g, alice@example.com, role:developers
    g, bob@example.com, role:operators
    g, admin@example.com, role:admin
```

### Sealed Secrets
```bash
# Установка Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Создать sealed secret
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```

## 📊 Monitoring и Notifications

### Prometheus Metrics
```yaml
# ServiceMonitor для ArgoCD
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
```

### Notifications
```yaml
# argocd-notifications-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: Application {{.app.metadata.name}} is now running version {{.app.status.sync.revision}}.
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

## 💡 Best Practices

1. **Используйте отдельные репозитории** - разделяйте код приложения и манифесты
2. **Автоматическая синхронизация** - включайте auto-sync для production
3. **Health checks** - настройте правильные health checks
4. **Pruning** - будьте осторожны с автоудалением ресурсов
5. **RBAC** - ограничивайте доступ по необходимости
6. **Мониторинг** - настройте метрики и алерты
7. **Backup** - делайте backup конфигурации ArgoCD
8. **Namespace изоляция** - используйте отдельные namespaces для окружений

## 📚 Полезные ссылки

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
