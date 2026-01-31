# Ansible - Полное руководство по использованию

## 📖 Введение

Этот гайд содержит готовые к использованию примеры Ansible для автоматизации инфраструктуры.

## 🗂️ Структура проекта

```
ansible/
├── ansible.cfg                    # Конфигурация Ansible
├── inventory/                     # Инвентарь серверов
│   ├── production                 # Production окружение
│   ├── staging                    # Staging окружение
│   └── local                      # Локальное тестирование
├── group_vars/                    # Переменные для групп
│   ├── all.yml                    # Общие переменные
│   ├── webservers.yml            # Переменные веб-серверов
│   └── databases.yml             # Переменные БД
├── host_vars/                     # Переменные для хостов
│   └── web1.example.com.yml
├── playbooks/                     # Playbooks
│   ├── site.yml                   # Главный playbook
│   ├── webservers.yml            # Настройка веб-серверов
│   ├── databases.yml             # Настройка БД
│   └── deploy-app.yml            # Деплой приложения
└── roles/                         # Роли
    ├── common/                    # Базовая настройка
    ├── webserver/                 # Nginx/Apache
    ├── database/                  # PostgreSQL/MySQL
    ├── docker/                    # Docker установка
    └── monitoring/                # Prometheus/Grafana
```

## 🚀 Быстрый старт

### 1. Настройка инвентаря

Отредактируйте `inventory/production`:

```ini
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[databases]
db1.example.com ansible_host=192.168.1.20

[all:vars]
ansible_user=deploy
ansible_become=yes
```

### 2. Проверка доступности хостов

```bash
# Ping всех хостов
ansible all -i inventory/production -m ping

# Выполнить команду на всех хостах
ansible all -i inventory/production -m shell -a "uptime"

# Собрать факты о хосте
ansible web1.example.com -i inventory/production -m setup
```

### 3. Запуск playbook

```bash
# Dry-run (проверка без изменений)
ansible-playbook -i inventory/production playbooks/site.yml --check

# Dry-run с показом изменений
ansible-playbook -i inventory/production playbooks/site.yml --check --diff

# Реальное выполнение
ansible-playbook -i inventory/production playbooks/site.yml

# С verbose режимом
ansible-playbook -i inventory/production playbooks/site.yml -vvv

# Только для конкретного хоста
ansible-playbook -i inventory/production playbooks/site.yml --limit web1.example.com

# Только конкретные теги
ansible-playbook -i inventory/production playbooks/site.yml --tags "nginx,ssl"

# Пропустить теги
ansible-playbook -i inventory/production playbooks/site.yml --skip-tags "backup"
```

## 📚 Подробные примеры

### Пример 1: Базовая настройка сервера

```bash
# Запустить роль common для всех серверов
ansible-playbook -i inventory/production playbooks/site.yml --tags common
```

Что делает роль `common`:
- ✅ Обновляет пакеты
- ✅ Настраивает timezone и locale
- ✅ Создает пользователей
- ✅ Настраивает SSH
- ✅ Устанавливает базовые пакеты
- ✅ Настраивает firewall

### Пример 2: Установка Nginx

```bash
# Установить Nginx на веб-серверы
ansible-playbook -i inventory/production playbooks/webservers.yml
```

Что делает роль `webserver`:
- ✅ Устанавливает Nginx
- ✅ Копирует конфигурацию
- ✅ Настраивает SSL сертификаты
- ✅ Настраивает виртуальные хосты
- ✅ Открывает порты в firewall

### Пример 3: Деплой приложения

```bash
# Деплой приложения версии 1.2.3
ansible-playbook -i inventory/production playbooks/deploy-app.yml -e "version=1.2.3"

# Деплой только на staging
ansible-playbook -i inventory/staging playbooks/deploy-app.yml
```

### Пример 4: Установка Docker

```bash
# Установить Docker на все хосты
ansible-playbook -i inventory/production playbooks/docker.yml
```

### Пример 5: Настройка мониторинга

```bash
# Установить Prometheus и Grafana
ansible-playbook -i inventory/production playbooks/monitoring.yml
```

## 🔧 Работа с переменными

### Глобальные переменные (`group_vars/all.yml`)

```yaml
# Timezone
timezone: "Europe/Moscow"

# NTP серверы
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

# DNS серверы
dns_servers:
  - 8.8.8.8
  - 8.8.4.4

# Пользователи
admin_users:
  - name: admin
    ssh_key: "ssh-rsa AAAAB3..."
```

### Переменные группы (`group_vars/webservers.yml`)

```yaml
nginx_version: "1.24"
nginx_worker_processes: auto
nginx_worker_connections: 1024

ssl_certificate_path: /etc/ssl/certs
ssl_key_path: /etc/ssl/private

domains:
  - name: example.com
    root: /var/www/example.com
    ssl: true
```

### Переменные хоста (`host_vars/web1.example.com.yml`)

```yaml
server_name: web1
server_role: primary
backup_enabled: true
```

### Использование переменных в командной строке

```bash
# Передать переменную
ansible-playbook playbooks/deploy.yml -e "version=1.2.3"

# Передать несколько переменных
ansible-playbook playbooks/deploy.yml -e "version=1.2.3 environment=production"

# Передать JSON
ansible-playbook playbooks/deploy.yml -e '{"version":"1.2.3","environment":"production"}'

# Использовать файл с переменными
ansible-playbook playbooks/deploy.yml -e "@vars/production.yml"
```

## 🎯 Ad-hoc команды (быстрые операции)

```bash
# Перезагрузить все веб-серверы
ansible webservers -i inventory/production -m reboot

# Обновить пакеты на всех серверах
ansible all -i inventory/production -m apt -a "update_cache=yes upgrade=dist"

# Скопировать файл
ansible webservers -i inventory/production -m copy -a "src=/local/file.txt dest=/remote/file.txt"

# Установить пакет
ansible all -i inventory/production -m apt -a "name=htop state=present"

# Перезапустить сервис
ansible webservers -i inventory/production -m systemd -a "name=nginx state=restarted"

# Создать директорию
ansible all -i inventory/production -m file -a "path=/opt/app state=directory owner=www-data mode=0755"

# Получить информацию о диске
ansible all -i inventory/production -m shell -a "df -h"

# Проверить статус сервиса
ansible webservers -i inventory/production -m systemd -a "name=nginx state=started enabled=yes"
```

## 🔒 Работа с секретами (Ansible Vault)

### Создание зашифрованного файла

```bash
# Создать новый vault файл
ansible-vault create group_vars/all/vault.yml

# Отредактировать
ansible-vault edit group_vars/all/vault.yml
```

Содержимое `vault.yml`:
```yaml
vault_database_password: "super_secret_password"
vault_api_key: "secret_api_key_12345"
vault_ssl_key_content: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
```

### Использование vault переменных

В `group_vars/all/vars.yml`:
```yaml
database_password: "{{ vault_database_password }}"
api_key: "{{ vault_api_key }}"
```

### Запуск с vault

```bash
# Запросить пароль интерактивно
ansible-playbook playbooks/site.yml --ask-vault-pass

# Использовать файл с паролем
echo "myVaultPassword123" > .vault_pass
chmod 600 .vault_pass
ansible-playbook playbooks/site.yml --vault-password-file .vault_pass

# Можно настроить в ansible.cfg
[defaults]
vault_password_file = .vault_pass
```

### Шифрование/расшифровка

```bash
# Зашифровать существующий файл
ansible-vault encrypt group_vars/production/secrets.yml

# Расшифровать файл
ansible-vault decrypt group_vars/production/secrets.yml

# Изменить пароль
ansible-vault rekey group_vars/production/secrets.yml

# Посмотреть зашифрованный файл
ansible-vault view group_vars/production/secrets.yml
```

## 📦 Использование ролей

### Установка роли из Ansible Galaxy

```bash
# Установить роль
ansible-galaxy install geerlingguy.nginx

# Установить конкретную версию
ansible-galaxy install geerlingguy.nginx,2.8.0

# Установить из requirements.yml
cat > requirements.yml <<EOF
roles:
  - name: geerlingguy.nginx
    version: 2.8.0
  - name: geerlingguy.postgresql
    version: 3.4.1
EOF

ansible-galaxy install -r requirements.yml
```

### Использование роли в playbook

```yaml
- hosts: webservers
  roles:
    - role: geerlingguy.nginx
      nginx_remove_default_vhost: true
      nginx_vhosts:
        - listen: "80"
          server_name: "example.com"
          root: "/var/www/html"
```

## 🎨 Динамический инвентарь

### AWS динамический инвентарь

```bash
# Установить boto3
pip install boto3

# Использовать AWS плагин
cat > inventory/aws_ec2.yml <<EOF
plugin: aws_ec2
regions:
  - us-east-1
  - eu-west-1
filters:
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: tags.Environment
    prefix: env
EOF

# Проверить инвентарь
ansible-inventory -i inventory/aws_ec2.yml --graph

# Использовать в playbook
ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml
```

## 🔍 Отладка и тестирование

### Отладка playbook

```bash
# Максимальный verbosity
ansible-playbook playbooks/site.yml -vvvv

# Показать переменные для хоста
ansible web1.example.com -i inventory/production -m debug -a "var=hostvars[inventory_hostname]"

# Step-by-step выполнение
ansible-playbook playbooks/site.yml --step

# Начать с определенной задачи
ansible-playbook playbooks/site.yml --start-at-task="Install nginx"
```

### Проверка синтаксиса

```bash
# Проверить синтаксис
ansible-playbook playbooks/site.yml --syntax-check

# Проверить с каким хостами будет работать
ansible-playbook playbooks/site.yml --list-hosts

# Показать задачи
ansible-playbook playbooks/site.yml --list-tasks

# Показать теги
ansible-playbook playbooks/site.yml --list-tags
```

### Molecule для тестирования ролей

```bash
# Установить molecule
pip install molecule molecule-docker

# Инициализировать роль с тестами
cd roles/
molecule init role my-role --driver-name docker

# Запустить тесты
cd my-role/
molecule test

# Создать инстанс для тестирования
molecule create
molecule converge
molecule verify
molecule destroy
```

## 📊 Производительность и оптимизация

### Параллельное выполнение

```yaml
# ansible.cfg
[defaults]
forks = 20  # Количество параллельных процессов
```

### Факты кеширование

```yaml
# ansible.cfg
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
```

### Pipelining (ускорение SSH)

```yaml
# ansible.cfg
[ssh_connection]
pipelining = True
```

### Отключение сбора фактов (если не нужны)

```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Simple task
      shell: echo "Hello"
```

## 💡 Best Practices

### 1. Идемпотентность
Убедитесь, что playbooks можно запускать многократно:

```yaml
# ❌ Плохо
- name: Add line to file
  shell: echo "new line" >> /etc/config

# ✅ Хорошо
- name: Ensure line in file
  lineinfile:
    path: /etc/config
    line: "new line"
    state: present
```

### 2. Используйте handlers

```yaml
tasks:
  - name: Copy nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: reload nginx

handlers:
  - name: reload nginx
    systemd:
      name: nginx
      state: reloaded
```

### 3. Проверки перед изменениями

```yaml
- name: Check if file exists
  stat:
    path: /etc/app/config
  register: config_file

- name: Create config if not exists
  template:
    src: config.j2
    dest: /etc/app/config
  when: not config_file.stat.exists
```

### 4. Используйте tags

```yaml
- name: Install nginx
  apt:
    name: nginx
    state: present
  tags:
    - nginx
    - packages

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - nginx
    - configuration
```

### 5. Документируйте роли

```yaml
# roles/webserver/meta/main.yml
galaxy_info:
  author: DevOps Team
  description: Install and configure Nginx web server
  license: MIT
  min_ansible_version: 2.10
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
dependencies:
  - role: common
```

## 📝 Примеры реальных сценариев

### Сценарий 1: Новый сервер setup

```bash
# 1. Базовая настройка
ansible-playbook -i inventory/production playbooks/site.yml --tags common --limit new-server.example.com

# 2. Установка роли (веб-сервер)
ansible-playbook -i inventory/production playbooks/webservers.yml --limit new-server.example.com

# 3. Деплой приложения
ansible-playbook -i inventory/production playbooks/deploy-app.yml --limit new-server.example.com
```

### Сценарий 2: Обновление приложения

```bash
# 1. Деплой новой версии на staging
ansible-playbook -i inventory/staging playbooks/deploy-app.yml -e "version=2.0.0"

# 2. Тесты...

# 3. Rolling update на production
ansible-playbook -i inventory/production playbooks/deploy-app.yml -e "version=2.0.0" --serial 1
```

### Сценарий 3: Аварийное восстановление

```bash
# 1. Остановить приложение
ansible-playbook -i inventory/production playbooks/stop-app.yml

# 2. Восстановить из backup
ansible-playbook -i inventory/production playbooks/restore-backup.yml -e "backup_date=2024-01-15"

# 3. Запустить приложение
ansible-playbook -i inventory/production playbooks/start-app.yml
```

## 🔗 Полезные ссылки

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Module Index](https://docs.ansible.com/ansible/latest/collections/index_module.html)
