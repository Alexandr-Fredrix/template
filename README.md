# DevOps Templates & Guides

Полный набор шаблонов и руководств для DevOps инженеров. Этот репозиторий содержит готовые к использованию конфигурации и подробные гайды по основным инструментам DevOps.

## 📋 Содержание

- **[Helm Charts](./helm-charts/)** - Шаблоны и гайды по созданию Helm чартов
- **[Dockerfiles](./dockerfiles/)** - Dockerfiles для разных языков программирования
- **[Docker Compose](./docker-compose/)** - Примеры docker-compose конфигураций
- **[GitLab CI/CD](./gitlab-ci/)** - Pipeline конфигурации для GitLab
  - [README-EXECUTORS.md](./gitlab-ci/README-EXECUTORS.md) - Docker & Kubernetes executors, Kaniko
  - [config-examples/](./gitlab-ci/config-examples/) - Конфиги для линтеров и тестов
- **[Kubernetes Manifests](./kubernetes-manifests/)** - Стандартные K8s манифесты
- **[Ansible](./ansible/)** - Playbooks и roles для автоматизации
  - [USAGE_GUIDE.md](./ansible/USAGE_GUIDE.md) - Полное руководство по использованию
  - [EXAMPLES.md](./ansible/EXAMPLES.md) - 12 практических сценариев
- **[ArgoCD](./argocd/)** - GitOps конфигурации для ArgoCD
- **[Bash Scripting](./bash-scripting/)** - Руководство по Bash scripting с примерами
  - [BASH_GUIDE.md](./bash-scripting/BASH_GUIDE.md) - Подробное руководство
  - [examples/](./bash-scripting/examples/) - 10 учебных примеров
  - [real-world/](./bash-scripting/examples/real-world/) - 4 production скрипта
- **[Databases](./databases/)** - Работа с базами данных для DevOps
  - [PostgreSQL](./databases/postgresql/) - Продвинутая реляционная БД
  - [MySQL](./databases/mysql/) - Популярная реляционная БД
  - [MongoDB](./databases/mongodb/) - NoSQL документо-ориентированная БД
  - [Comparison](./databases/comparison.md) - Сравнение и выбор БД

## 🚀 Быстрый старт

Каждая директория содержит:
- 📖 **README.md** - подробное руководство
- 📝 **Готовые шаблоны** - примеры для быстрого старта
- 💡 **Best practices** - лучшие практики использования

## 🛠️ Как использовать

1. Выберите нужный раздел из содержания
2. Прочитайте README в соответствующей директории
3. Скопируйте нужный шаблон
4. Адаптируйте под свой проект

## 📚 Структура проекта

```
devops-templates-guide/
├── helm-charts/          # Helm чарты
│   ├── README.md
│   └── templates/
├── dockerfiles/          # Docker образы
│   ├── README.md
│   └── [language]/
├── docker-compose/       # Docker Compose
│   ├── README.md
│   └── examples/
├── gitlab-ci/           # GitLab CI/CD
│   ├── README.md
│   └── pipelines/
├── kubernetes-manifests/ # K8s манифесты
│   ├── README.md
│   └── resources/
├── ansible/             # Ansible
│   ├── README.md
│   └── playbooks/
├── argocd/              # ArgoCD GitOps
│   ├── README.md
│   └── applications/
├── bash-scripting/       # Bash scripting
│   ├── BASH_GUIDE.md
│   ├── examples/
│   └── templates/
└── databases/            # Работа с БД
    ├── postgresql/
    ├── mysql/
    └── mongodb/
```

## 🤝 Вклад

Приветствуются pull request'ы с улучшениями и дополнениями!

## 📝 Лицензия

MIT License - свободно используйте в своих проектах.

## 📞 Полезные ссылки

- [Helm Documentation](https://helm.sh/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Ansible Documentation](https://docs.ansible.com/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
