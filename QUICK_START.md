# 🚀 Быстрый старт

## Что внутри?

Этот репозиторий содержит готовые к использованию шаблоны и подробные гайды для всех основных DevOps инструментов.

## 📁 Структура репозитория

```
devops-templates-guide/
│
├── 📦 helm-charts/              - Helm чарты для Kubernetes
│   └── web-application-template/ - Полный production-ready чарт
│
├── 🐳 dockerfiles/              - Dockerfiles для разных языков
│   ├── nodejs/                  - Node.js, TypeScript, Next.js
│   ├── python/                  - Python, Django, FastAPI
│   ├── golang/                  - Go с multi-stage build
│   ├── java/                    - Java Spring Boot (Maven/Gradle)
│   ├── php/                     - PHP с Nginx
│   ├── dotnet/                  - .NET приложения
│   └── rust/                    - Rust приложения
│
├── 🐙 docker-compose/           - Docker Compose примеры
│   └── examples/
│       ├── full-stack-app.yml   - Frontend + Backend + DB + Redis
│       ├── monitoring-stack.yml - Prometheus + Grafana + Loki
│       ├── microservices.yml    - Микросервисная архитектура
│       └── wordpress.yml        - WordPress стек
│
├── 🦊 gitlab-ci/                - GitLab CI/CD пайплайны
│   └── pipelines/
│       ├── nodejs-docker-k8s.yml      - Node.js → Docker → K8s
│       ├── python-django.yml          - Django с тестами
│       └── monorepo-microservices.yml - Monorepo оптимизация
│
├── ☸️  kubernetes-manifests/    - Kubernetes манифесты
│   └── complete-app/            - Полный набор для production
│       ├── 01-namespace.yaml
│       ├── 02-configmap.yaml
│       ├── 03-secret.yaml
│       ├── 04-deployment.yaml   - С probes, resources, security
│       ├── 05-service.yaml
│       ├── 06-ingress.yaml      - С TLS, rate limiting
│       ├── 07-hpa.yaml          - Автомасштабирование
│       ├── 08-pdb.yaml          - Pod disruption budget
│       ├── 09-serviceaccount-rbac.yaml
│       ├── 10-networkpolicy.yaml
│       └── 11-cronjob.yaml
│
├── 🤖 ansible/                  - Ansible automation
│   ├── playbooks/               - Готовые playbooks
│   ├── roles/                   - Переиспользуемые роли
│   └── inventory/               - Примеры инвентаря
│
└── 🔄 argocd/                   - GitOps с ArgoCD
    ├── applications/            - Application манифесты
    ├── app-of-apps/            - App of Apps pattern
    └── applicationsets/         - Multi-cluster деплой
```

## 🎯 Как использовать

### 1️⃣ Для Helm Charts
```bash
cd helm-charts/web-application-template

# Просмотр что будет создано
helm template myapp . -f values.yaml

# Установка
helm install myapp . -f values.yaml

# С кастомными параметрами
helm install myapp . --set replicaCount=5 --set image.tag=v1.2.3
```

### 2️⃣ Для Docker
```bash
cd dockerfiles/nodejs

# Сборка
docker build -t myapp:latest .

# С multi-stage для production
docker build -t myapp:prod --target runtime-alpine -f Dockerfile .
```

### 3️⃣ Для Docker Compose
```bash
cd docker-compose/examples

# Скопировать и настроить переменные
cp .env.example .env
nano .env

# Запуск
docker-compose -f full-stack-app.yml up -d

# Логи
docker-compose -f full-stack-app.yml logs -f
```

### 4️⃣ Для GitLab CI
```bash
# Скопировать нужный pipeline в корень вашего проекта
cp gitlab-ci/pipelines/nodejs-docker-k8s.yml .gitlab-ci.yml

# Настроить переменные в GitLab:
# Settings → CI/CD → Variables
# - KUBE_URL
# - KUBE_TOKEN
# - CI_REGISTRY_PASSWORD
```

### 5️⃣ Для Kubernetes
```bash
cd kubernetes-manifests/complete-app

# Просмотр изменений
kubectl apply -f . --dry-run=client

# Деплой
kubectl apply -f .

# Проверка
kubectl get all -n myapp
```

### 6️⃣ Для Ansible
```bash
cd ansible

# Настроить inventory
vim inventory/production

# Dry-run
ansible-playbook -i inventory/production playbooks/deploy-app.yml --check

# Выполнить
ansible-playbook -i inventory/production playbooks/deploy-app.yml
```

### 7️⃣ Для ArgoCD
```bash
cd argocd/applications

# Адаптировать манифест под свой проект
vim simple-app.yaml

# Применить
kubectl apply -f simple-app.yaml

# Проверить статус
argocd app get simple-webapp
```

## ⚙️ Адаптация под ваш проект

Во всех шаблонах замените:
- ✏️ `myapp` → имя вашего приложения
- ✏️ `example.com` → ваш домен
- ✏️ `changeme123` → используйте secrets management!
- ✏️ `registry.example.com` → ваш Docker registry

## 🔒 Важно для Production

### Безопасность
- ❌ **НЕ** коммитьте пароли в Git!
- ✅ Используйте Kubernetes Secrets
- ✅ Используйте Vault, Sealed Secrets или External Secrets
- ✅ Используйте GitLab CI/CD Variables или GitHub Secrets

### Тестирование
```bash
# Kubernetes
kubectl apply --dry-run=server -f manifest.yaml

# Helm
helm install --dry-run --debug myapp ./chart

# Ansible
ansible-playbook playbook.yml --check --diff

# Docker Compose
docker-compose config
```

## 📚 Документация

Каждая директория содержит подробный README.md с:
- 📖 Подробным описанием инструмента
- 🎯 Пошаговыми инструкциями
- 💡 Best practices
- 🔧 Примерами команд
- 🔗 Ссылками на официальную документацию

## 🆘 Нужна помощь?

1. Прочитайте `README.md` в нужной директории
2. Посмотрите примеры в `examples/` или `templates/`
3. Проверьте `CONTRIBUTING.md` для деталей

## 🎓 Обучающие материалы

Каждый README содержит:
- Базовые концепции
- Структуру файлов
- Основные команды
- Расширенные возможности
- Примеры реальных кейсов

## 📊 Чек-лист для Production

- [ ] Resources limits установлены
- [ ] Health checks настроены
- [ ] Secrets вынесены в secret management
- [ ] Мониторинг настроен
- [ ] Логирование работает
- [ ] Backup настроен
- [ ] RBAC настроен
- [ ] Network policies применены
- [ ] TLS/SSL настроен
- [ ] Autoscaling настроен (если нужен)

## 🚀 Следующие шаги

1. Выберите нужный инструмент из списка выше
2. Перейдите в соответствующую директорию
3. Прочитайте README.md
4. Скопируйте нужный шаблон
5. Адаптируйте под свой проект
6. Протестируйте
7. Деплойте!

Удачи! 🎉
