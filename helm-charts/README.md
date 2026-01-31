# Helm Charts - Руководство и Шаблоны

## 📖 Что такое Helm?

Helm - это пакетный менеджер для Kubernetes. Он позволяет упаковывать, настраивать и развертывать приложения в Kubernetes.

## 🏗️ Структура Helm Chart

```
my-app-chart/
├── Chart.yaml           # Метаданные чарта
├── values.yaml          # Значения по умолчанию
├── charts/              # Зависимые чарты
├── templates/           # Шаблоны манифестов K8s
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   ├── _helpers.tpl     # Вспомогательные функции
│   └── NOTES.txt        # Инструкции после установки
└── .helmignore          # Файлы для игнорирования
```

## 📝 Основные команды Helm

```bash
# Создать новый чарт
helm create my-app

# Проверить синтаксис
helm lint ./my-app

# Показать итоговые манифесты
helm template my-app ./my-app

# Установить чарт
helm install my-release ./my-app

# Обновить релиз
helm upgrade my-release ./my-app

# Откатить релиз
helm rollback my-release 1

# Удалить релиз
helm uninstall my-release

# Список релизов
helm list

# Упаковать чарт
helm package ./my-app

# Добавить репозиторий
helm repo add stable https://charts.helm.sh/stable
```

## 🎯 Создание своего чарта - Пошаговая инструкция

### Шаг 1: Chart.yaml

Файл с метаданными чарта:

```yaml
apiVersion: v2
name: my-application
description: A Helm chart for my application
type: application
version: 1.0.0      # Версия чарта
appVersion: "1.0"   # Версия приложения
keywords:
  - web
  - api
maintainers:
  - name: Your Name
    email: your.email@example.com
```

### Шаг 2: values.yaml

Конфигурационные параметры (можно переопределять при установке):

```yaml
# Количество реплик
replicaCount: 2

# Образ контейнера
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

# Переменные окружения
env:
  - name: ENVIRONMENT
    value: "production"
  - name: LOG_LEVEL
    value: "info"

# Ресурсы
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Service
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

# ConfigMap данные
config:
  application.conf: |
    server.port=8080
    logging.level=INFO

# Liveness и Readiness пробы
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Шаг 3: templates/_helpers.tpl

Вспомогательные функции для переиспользования:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-app.labels" -}}
helm.sh/chart: {{ include "my-app.chart" . }}
{{ include "my-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "my-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

## 💡 Best Practices

1. **Используйте values.yaml** - все параметры должны быть настраиваемыми
2. **Добавляйте документацию** - комментарии в values.yaml
3. **Версионирование** - семантическое версионирование для чартов
4. **Тестирование** - используйте `helm lint` и `helm template`
5. **Условная логика** - используйте `if/else` для опциональных ресурсов
6. **Labels и Annotations** - стандартизированные метки
7. **Безопасность** - не храните секреты в values.yaml напрямую
8. **Зависимости** - используйте charts/ для зависимых чартов

## 🔧 Переопределение значений

```bash
# Через командную строку
helm install my-release ./my-app --set replicaCount=3

# Через файл
helm install my-release ./my-app -f custom-values.yaml

# Множественные значения
helm install my-release ./my-app \
  --set image.tag=2.0 \
  --set service.type=LoadBalancer
```

## 📦 Публикация чарта

```bash
# Упаковать чарт
helm package my-app/

# Создать индексный файл для репозитория
helm repo index .

# Опубликовать в Helm репозиторий (например GitHub Pages)
# Загрузить my-app-1.0.0.tgz и index.yaml
```

## 🔍 Отладка

```bash
# Показать итоговые манифесты
helm template my-release ./my-app --debug

# Проверить значения
helm get values my-release

# Посмотреть историю релизов
helm history my-release

# Dry-run установки
helm install my-release ./my-app --dry-run --debug
```

## 📚 Дополнительные материалы

- [Официальная документация Helm](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [ArtifactHub](https://artifacthub.io/) - публичные Helm чарты
