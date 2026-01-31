# Ansible - Руководство и Шаблоны

## 📖 Что такое Ansible?

Ansible - это инструмент автоматизации IT, который позволяет управлять конфигурацией, развертыванием приложений и оркестрацией задач. Использует YAML для описания задач и не требует агентов на управляемых хостах.

## 🏗️ Основная структура проекта

```
ansible-project/
├── ansible.cfg           # Конфигурация Ansible
├── inventory/            # Инвентарь хостов
│   ├── production
│   └── staging
├── group_vars/           # Переменные для групп
│   ├── all.yml
│   ├── webservers.yml
│   └── databases.yml
├── host_vars/            # Переменные для хостов
│   └── web1.yml
├── roles/                # Роли
│   ├── common/
│   ├── webserver/
│   └── database/
├── playbooks/            # Playbooks
│   ├── site.yml
│   ├── deploy.yml
│   └── backup.yml
└── files/                # Статические файлы
    └── configs/
```

## 📋 Основные концепции

### Inventory (Инвентарь)
```ini
# inventory/production
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[databases]
db1.example.com ansible_host=192.168.1.20
db2.example.com ansible_host=192.168.1.21

[loadbalancers]
lb1.example.com ansible_host=192.168.1.30

[production:children]
webservers
databases
loadbalancers

[production:vars]
ansible_user=deploy
ansible_become=yes
ansible_become_method=sudo
```

### YAML формат inventory
```yaml
# inventory/production.yml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_host: 192.168.1.10
        web2.example.com:
          ansible_host: 192.168.1.11
      vars:
        http_port: 80
    databases:
      hosts:
        db1.example.com:
          ansible_host: 192.168.1.20
```

### Playbook
```yaml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Copy config file
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx

  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

### Role структура
```
roles/webserver/
├── defaults/         # Переменные по умолчанию
│   └── main.yml
├── files/            # Статические файлы
│   └── index.html
├── handlers/         # Обработчики событий
│   └── main.yml
├── meta/             # Метаданные роли
│   └── main.yml
├── tasks/            # Основные задачи
│   └── main.yml
├── templates/        # Шаблоны Jinja2
│   └── nginx.conf.j2
├── tests/            # Тесты
│   └── test.yml
└── vars/             # Переменные роли
    └── main.yml
```

## 🎯 Основные команды

```bash
# Проверка доступности хостов
ansible all -i inventory/production -m ping

# Выполнить ad-hoc команду
ansible webservers -i inventory/production -m shell -a "uptime"

# Запустить playbook
ansible-playbook -i inventory/production playbooks/site.yml

# Запустить с verbose
ansible-playbook -i inventory/production playbooks/site.yml -v
ansible-playbook -i inventory/production playbooks/site.yml -vvv

# Dry-run (check mode)
ansible-playbook -i inventory/production playbooks/site.yml --check

# Diff mode (показать изменения)
ansible-playbook -i inventory/production playbooks/site.yml --check --diff

# Ограничить выполнение определенными хостами
ansible-playbook -i inventory/production playbooks/site.yml --limit web1.example.com

# Запустить с определенными тегами
ansible-playbook -i inventory/production playbooks/site.yml --tags "configuration,deployment"

# Пропустить теги
ansible-playbook -i inventory/production playbooks/site.yml --skip-tags "backup"

# Запустить с дополнительными переменными
ansible-playbook -i inventory/production playbooks/deploy.yml -e "version=1.2.3"

# Посмотреть доступные факты о хосте
ansible web1.example.com -i inventory/production -m setup

# Создать роль
ansible-galaxy init roles/my-role

# Установить роль из Ansible Galaxy
ansible-galaxy install geerlingguy.nginx

# Проверить синтаксис playbook
ansible-playbook playbooks/site.yml --syntax-check

# Список хостов
ansible-inventory -i inventory/production --list
ansible-inventory -i inventory/production --graph

# Зашифровать файл с секретами
ansible-vault create secrets.yml
ansible-vault encrypt secrets.yml
ansible-vault decrypt secrets.yml
ansible-vault edit secrets.yml

# Запустить playbook с vault
ansible-playbook -i inventory/production playbooks/site.yml --ask-vault-pass
ansible-playbook -i inventory/production playbooks/site.yml --vault-password-file ~/.vault_pass
```

## 💡 Полезные модули

### Управление пакетами
```yaml
# APT (Debian/Ubuntu)
- name: Install packages
  apt:
    name:
      - nginx
      - postgresql
    state: present
    update_cache: yes

# YUM (RHEL/CentOS)
- name: Install packages
  yum:
    name: nginx
    state: latest

# Package (универсальный)
- name: Install package
  package:
    name: nginx
    state: present
```

### Управление файлами
```yaml
# Копирование файла
- name: Copy file
  copy:
    src: /local/path/file.txt
    dest: /remote/path/file.txt
    owner: www-data
    group: www-data
    mode: '0644'

# Шаблон
- name: Template config
  template:
    src: config.j2
    dest: /etc/app/config.conf
    backup: yes

# Создать директорию
- name: Create directory
  file:
    path: /var/www/app
    state: directory
    owner: www-data
    mode: '0755'

# Создать симлинк
- name: Create symlink
  file:
    src: /opt/app/current
    dest: /var/www/app
    state: link
```

### Управление сервисами
```yaml
# Systemd
- name: Start and enable service
  systemd:
    name: nginx
    state: started
    enabled: yes
    daemon_reload: yes

# Service (универсальный)
- name: Restart service
  service:
    name: nginx
    state: restarted
```

### Выполнение команд
```yaml
# Shell
- name: Run shell command
  shell: |
    cd /opt/app
    npm install
    npm run build
  args:
    chdir: /opt/app

# Command
- name: Run command
  command: /usr/bin/myapp --version
  register: app_version

# Script
- name: Run script
  script: /local/scripts/deploy.sh
```

### Git
```yaml
- name: Clone repository
  git:
    repo: https://github.com/user/repo.git
    dest: /opt/app
    version: main
    force: yes
```

### Docker
```yaml
- name: Start container
  docker_container:
    name: myapp
    image: myapp:latest
    state: started
    ports:
      - "8080:8080"
    env:
      DATABASE_URL: "{{ database_url }}"
```

## 🔧 Расширенные возможности

### Variables (Переменные)
```yaml
# В playbook
vars:
  http_port: 80
  server_name: example.com

# В файле
vars_files:
  - vars/main.yml

# Использование переменных
- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/{{ server_name }}

# Register (сохранение вывода)
- name: Get app version
  command: /usr/bin/myapp --version
  register: app_version

- name: Print version
  debug:
    msg: "App version: {{ app_version.stdout }}"
```

### Conditionals (Условия)
```yaml
- name: Install on Debian
  apt:
    name: nginx
  when: ansible_os_family == "Debian"

- name: Install on RedHat
  yum:
    name: nginx
  when: ansible_os_family == "RedHat"

- name: Check if file exists
  stat:
    path: /etc/app/config
  register: config_file

- name: Copy config if not exists
  copy:
    src: config
    dest: /etc/app/config
  when: not config_file.stat.exists
```

### Loops (Циклы)
```yaml
# Простой цикл
- name: Install packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - postgresql
    - redis

# Цикл с dict
- name: Create users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
  loop:
    - { name: 'alice', groups: 'admin' }
    - { name: 'bob', groups: 'developers' }

# With_dict
- name: Set variables
  set_fact:
    "{{ item.key }}": "{{ item.value }}"
  with_dict:
    http_port: 80
    https_port: 443
```

### Handlers (Обработчики)
```yaml
# В tasks
- name: Copy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify:
    - reload nginx
    - send notification

# В handlers/main.yml
- name: reload nginx
  service:
    name: nginx
    state: reloaded

- name: send notification
  shell: echo "Config changed" | mail -s "Alert" admin@example.com
```

### Tags (Теги)
```yaml
- name: Install packages
  apt:
    name: nginx
  tags:
    - packages
    - nginx

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - configuration
    - nginx

- name: Deploy application
  copy:
    src: app/
    dest: /var/www/app/
  tags:
    - deployment
```

### Blocks (Блоки)
```yaml
- block:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx
      service:
        name: nginx
        state: started
  rescue:
    - name: Print error
      debug:
        msg: "Failed to install/start nginx"
  always:
    - name: Clean up
      file:
        path: /tmp/install.log
        state: absent
```

## 🔒 Ansible Vault

```bash
# Создать зашифрованный файл
ansible-vault create secrets.yml

# Зашифровать существующий файл
ansible-vault encrypt vars/secrets.yml

# Расшифровать файл
ansible-vault decrypt vars/secrets.yml

# Редактировать зашифрованный файл
ansible-vault edit vars/secrets.yml

# Изменить пароль
ansible-vault rekey vars/secrets.yml

# Использование в playbook
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

## 📚 Полезные ссылки

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
