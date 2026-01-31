# Структура проекта DevOps Templates & Guides

Полное описание организации файлов и директорий в проекте.

## 📁 Корневая структура

```
devops-templates-guide/
├── .gitignore              # Игнорируемые файлы
├── LICENSE                 # MIT лицензия
├── README.md              # Главная документация
├── CONTRIBUTING.md        # Руководство для контрибьюторов
├── CHANGELOG.md           # История изменений
├── QUICK_START.md         # Быстрый старт
├── STRUCTURE.md           # Этот файл
│
├── ansible/               # Ansible автоматизация
├── argocd/                # ArgoCD GitOps
├── bash-scripting/        # Bash скрипты
├── databases/             # Работа с БД
├── docker-compose/        # Docker Compose примеры
├── dockerfiles/           # Dockerfiles для языков
├── gitlab-ci/             # GitLab CI/CD
├── helm-charts/           # Helm charts
└── kubernetes-manifests/  # Kubernetes манифесты
```

## 🗂️ Детальная структура

### ansible/ - Автоматизация с Ansible

```
ansible/
├── README.md                    # Обзор Ansible
├── USAGE_GUIDE.md              # Полное руководство по использованию
├── EXAMPLES.md                 # 12 практических сценариев
├── ansible.cfg                 # Конфигурация Ansible
│
├── inventory/                  # Инвентари
│   ├── production             # Production серверы
│   └── staging                # Staging серверы
│
├── group_vars/                # Переменные для групп
│   ├── all.yml               # Общие переменные
│   ├── webservers.yml        # Переменные веб-серверов
│   ├── databases.yml         # Переменные БД
│   └── production.yml        # Production переменные
│
├── host_vars/                # Переменные для хостов
│
├── playbooks/                # Playbooks
│   ├── site.yml             # Основной playbook
│   ├── webservers.yml       # Настройка веб-серверов
│   ├── databases.yml        # Настройка БД
│   └── deploy-app.yml       # Деплой приложения
│
└── roles/                    # Роли
    ├── common/              # Базовая настройка
    ├── webserver/           # Nginx/Apache
    ├── database/            # PostgreSQL/MySQL
    ├── docker/              # Docker установка
    └── monitoring/          # Prometheus/Grafana
```

### argocd/ - GitOps с ArgoCD

```
argocd/
├── README.md
│
├── applications/            # Application манифесты
│   ├── app-example.yaml
│   └── multi-env-app.yaml
│
├── applicationsets/         # ApplicationSets
│   ├── monorepo-apps.yaml
│   └── multi-cluster.yaml
│
└── app-of-apps/            # App of Apps паттерн
    └── root-app.yaml
```

### bash-scripting/ - Bash скрипты

```
bash-scripting/
├── README.md                # Обзор и быстрый старт
├── BASH_GUIDE.md           # Полное руководство (1400+ строк)
│
├── examples/               # Учебные примеры
│   ├── 01-basic-script.sh
│   ├── 02-variables.sh
│   ├── 03-functions.sh
│   ├── 04-loops.sh
│   ├── 05-conditionals.sh
│   ├── 06-arrays.sh
│   ├── 07-file-operations.sh
│   ├── 08-string-manipulation.sh
│   ├── 09-error-handling.sh
│   ├── 10-arguments.sh
│   └── real-world/         # Production примеры
│       ├── backup-script.sh
│       ├── deployment-script.sh
│       ├── log-analyzer.sh
│       └── system-monitor.sh
│
└── templates/              # Шаблоны для начала
    ├── basic-template.sh
    ├── deployment-template.sh
    └── monitoring-template.sh
```

### databases/ - Работа с базами данных

```
databases/
├── README.md               # Обзор всех БД
├── comparison.md           # Сравнение PostgreSQL vs MySQL vs MongoDB
│
├── postgresql/            # PostgreSQL
│   ├── README.md         # Руководство
│   ├── commands.md       # Справочник команд
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── postgresql.conf
│   │   └── pg_hba.conf
│   └── scripts/
│       └── backup-postgres.sh
│
├── mysql/                # MySQL/MariaDB
│   ├── README.md
│   ├── docker/
│   │   └── docker-compose.yml
│   └── scripts/
│       └── backup-mysql.sh
│
└── mongodb/              # MongoDB
    ├── README.md
    ├── docker/
    │   └── docker-compose.yml
    └── scripts/
        └── backup-mongodb.sh
```

### docker-compose/ - Docker Compose примеры

```
docker-compose/
├── README.md
│
└── examples/
    ├── fullstack-app/          # Full-stack приложение
    ├── monitoring-stack/       # Prometheus + Grafana
    ├── microservices/          # Микросервисы
    └── wordpress/              # WordPress
```

### dockerfiles/ - Dockerfiles для языков

```
dockerfiles/
├── README.md
│
├── nodejs/
│   ├── Dockerfile
│   ├── Dockerfile.multi-stage
│   └── .dockerignore
│
├── python/
├── java/
├── golang/
├── php/
├── dotnet/
├── rust/
└── ruby/
```

### gitlab-ci/ - GitLab CI/CD

```
gitlab-ci/
├── README.md                      # Обзор
├── README-EXECUTORS.md            # Docker vs K8s executors
├── DEPLOYMENT_COMPARISON.md       # Сравнение методов деплоя
├── SINGLE_REPO_GUIDE.md          # Single repo деплой
├── TWO_REPO_GUIDE.md             # Two repo GitOps
│
├── config-examples/              # Конфиги линтеров
│   ├── .eslintrc.json
│   ├── .prettierrc
│   ├── jest.config.js
│   ├── pytest.ini
│   └── .yamllint.yml
│
└── pipelines/                    # Pipeline примеры
    ├── nodejs-complete.yml
    ├── python-complete.yml
    ├── docker-executor-advanced.yml
    ├── kubernetes-executor-kaniko.yml
    ├── testing-complete.yml
    ├── app-repository.yml        # App repo (GitOps)
    ├── infra-repository.yml      # Infra repo (GitOps)
    ├── single-repo-kubeconfig.yml
    ├── single-repo-k8s-runner.yml
    └── monorepo.yml
```

### helm-charts/ - Helm charts

```
helm-charts/
├── README.md
│
└── web-application-template/
    ├── Chart.yaml
    ├── values.yaml
    ├── values-staging.yaml
    ├── values-production.yaml
    ├── .helmignore
    │
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        ├── configmap.yaml
        ├── secret.yaml
        ├── hpa.yaml
        ├── pdb.yaml
        ├── serviceaccount.yaml
        ├── rbac.yaml
        └── networkpolicy.yaml
```

### kubernetes-manifests/ - Kubernetes манифесты

```
kubernetes-manifests/
├── README.md
│
├── complete-app/              # Полное приложение
│   ├── 01-namespace.yaml
│   ├── 02-configmap.yaml
│   ├── 03-secret.yaml
│   ├── 04-deployment.yaml
│   ├── 05-service.yaml
│   ├── 06-ingress.yaml
│   ├── 07-hpa.yaml
│   ├── 08-pdb.yaml
│   ├── 09-serviceaccount.yaml
│   ├── 10-rbac.yaml
│   └── 11-networkpolicy.yaml
│
└── resources/                 # Отдельные ресурсы
    ├── statefulset-example.yaml
    ├── daemonset-example.yaml
    ├── job-example.yaml
    └── cronjob-example.yaml
```

## 📝 Соглашения об именовании

### Файлы

- **README.md** - Главная документация директории
- **GUIDE.md** - Подробные руководства (например, BASH_GUIDE.md)
- **EXAMPLES.md** - Коллекция примеров
- **\*.yml/\*.yaml** - YAML конфигурации
- **\*.sh** - Bash скрипты (исполняемые)
- **\*.md** - Markdown документация

### Директории

- **examples/** - Примеры использования
- **scripts/** - Автоматизационные скрипты
- **docker/** - Docker/Docker Compose файлы
- **templates/** - Шаблоны для начала работы
- **config-examples/** - Примеры конфигураций

## 🎯 Принципы организации

1. **Самодостаточность** - Каждая директория содержит README.md
2. **Примеры** - Готовые к использованию примеры в каждом разделе
3. **Документация** - Подробные гайды для сложных тем
4. **Единообразие** - Одинаковая структура для похожих разделов
5. **Практичность** - Акцент на production-ready решения

## 🔍 Как найти нужное

### По инструменту

- **Ansible** → `ansible/`
- **ArgoCD** → `argocd/`
- **Bash** → `bash-scripting/`
- **Docker** → `dockerfiles/`, `docker-compose/`
- **GitLab CI** → `gitlab-ci/`
- **Helm** → `helm-charts/`
- **Kubernetes** → `kubernetes-manifests/`
- **Databases** → `databases/`

### По задаче

- **Автоматизация** → `ansible/`, `bash-scripting/`
- **CI/CD** → `gitlab-ci/`
- **Контейнеризация** → `dockerfiles/`, `docker-compose/`
- **Оркестрация** → `kubernetes-manifests/`, `helm-charts/`
- **GitOps** → `argocd/`, `gitlab-ci/TWO_REPO_GUIDE.md`
- **Базы данных** → `databases/`
- **Мониторинг** → `ansible/roles/monitoring/`, `docker-compose/examples/monitoring-stack/`

### По уровню

- **Новичок** → Начните с README.md каждого раздела
- **Средний** → Изучите GUIDE файлы и examples
- **Продвинутый** → Смотрите real-world примеры и production configs

## 📊 Статистика проекта

- **Общее количество файлов:** 130+
- **Общее количество директорий:** 85+
- **Строк кода/конфигураций:** 22,000+
- **Markdown документации:** 25+ файлов
- **Готовых скриптов:** 20+
- **Docker Compose примеров:** 10+
- **GitLab CI пайплайнов:** 10+

## 🔄 Обновления структуры

При добавлении нового раздела:

1. Создайте директорию с понятным именем
2. Добавьте README.md с описанием
3. Организуйте файлы по поддиректориям (examples/, scripts/, docker/)
4. Обновите главный README.md
5. Обновите этот файл (STRUCTURE.md)
6. Создайте коммит с описанием

## 📞 Вопросы

Если структура неясна или нужна помощь:

1. Посмотрите QUICK_START.md
2. Изучите CONTRIBUTING.md
3. Создайте Issue на GitHub
