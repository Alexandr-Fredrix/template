# Как использовать этот репозиторий

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
git clone <your-repo-url>
cd devops-templates-guide
```

### 2. Выбор нужного шаблона
Перейдите в соответствующую директорию:
- `helm-charts/` - Helm чарты
- `dockerfiles/` - Dockerfiles для разных языков
- `docker-compose/` - Docker Compose примеры
- `gitlab-ci/` - GitLab CI/CD пайплайны
- `kubernetes-manifests/` - Kubernetes манифесты
- `ansible/` - Ansible playbooks и роли
- `argocd/` - ArgoCD конфигурации

### 3. Адаптация под свой проект
1. Скопируйте нужный шаблон в свой проект
2. Замените placeholder значения на свои:
   - `myapp` → имя вашего приложения
   - `example.com` → ваш домен
   - `changeme123` → реальные пароли (через secrets!)
3. Настройте переменные окружения
4. Протестируйте конфигурацию

## 📚 Примеры использования

### Helm Charts
```bash
cd helm-charts/web-application-template
helm install my-release . -f custom-values.yaml
```

### Docker Compose
```bash
cd docker-compose/examples
cp .env.example .env
# Отредактируйте .env
docker-compose -f full-stack-app.yml up -d
```

### GitLab CI
```bash
# Скопируйте нужный pipeline в свой проект
cp gitlab-ci/pipelines/nodejs-docker-k8s.yml .gitlab-ci.yml
# Настройте переменные в GitLab CI/CD Settings
```

### Kubernetes
```bash
cd kubernetes-manifests/complete-app
# Просмотрите и адаптируйте манифесты
kubectl apply -f .
```

### Ansible
```bash
cd ansible
# Настройте inventory
vim inventory/production
# Запустите playbook
ansible-playbook -i inventory/production playbooks/deploy-app.yml
```

### ArgoCD
```bash
cd argocd/applications
# Адаптируйте Application манифест
kubectl apply -f simple-app.yaml
```

## 🔧 Рекомендации

### Безопасность
- ❌ Никогда не коммитьте реальные пароли и ключи
- ✅ Используйте secrets management (Vault, Sealed Secrets, External Secrets)
- ✅ Используйте `.env` файлы для локальной разработки (добавлены в .gitignore)
- ✅ Для production используйте GitLab CI/CD Variables, GitHub Secrets или подобное

### Версионирование
- Используйте семантическое версионирование (SemVer)
- Тегируйте Docker образы конкретными версиями, а не `latest`
- Сохраняйте историю изменений в CHANGELOG.md

### Тестирование
- Всегда тестируйте в dev/staging перед production
- Используйте `--dry-run` для Kubernetes
- Используйте `--check` для Ansible
- Используйте `helm template` для проверки Helm чартов

## 🤝 Внесение улучшений

Если вы хотите улучшить шаблоны:

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Создайте Pull Request

## 📝 Структура проекта

```
devops-templates-guide/
├── README.md                 # Главная документация
├── CONTRIBUTING.md           # Этот файл
├── LICENSE                   # Лицензия
├── .gitignore               # Игнорируемые файлы
│
├── helm-charts/             # Helm чарты
│   ├── README.md            # Документация Helm
│   └── web-application-template/  # Готовый шаблон
│
├── dockerfiles/             # Dockerfiles
│   ├── README.md
│   ├── nodejs/              # Node.js примеры
│   ├── python/              # Python примеры
│   ├── golang/              # Go примеры
│   └── ...                  # Другие языки
│
├── docker-compose/          # Docker Compose
│   ├── README.md
│   └── examples/            # Готовые примеры стеков
│
├── gitlab-ci/               # GitLab CI/CD
│   ├── README.md
│   └── pipelines/           # Примеры пайплайнов
│
├── kubernetes-manifests/    # Kubernetes
│   ├── README.md
│   └── complete-app/        # Полный набор манифестов
│
├── ansible/                 # Ansible
│   ├── README.md
│   ├── playbooks/           # Playbooks
│   └── roles/               # Роли
│
└── argocd/                  # ArgoCD
    ├── README.md
    ├── applications/        # Application манифесты
    └── applicationsets/     # ApplicationSets
```

## 💡 Полезные команды

### Проверка синтаксиса
```bash
# YAML
yamllint file.yaml

# Dockerfile
hadolint Dockerfile

# Kubernetes
kubectl apply --dry-run=client -f manifest.yaml
kubectl apply --dry-run=server -f manifest.yaml

# Helm
helm lint ./chart
helm template myrelease ./chart

# Ansible
ansible-playbook playbook.yml --syntax-check
```

## 🆘 Получение помощи

- Прочитайте README.md в соответствующей директории
- Проверьте примеры в `examples/` или `templates/`
- Обратитесь к официальной документации инструментов
- Создайте Issue в репозитории
