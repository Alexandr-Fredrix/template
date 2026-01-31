# Ansible - Практические примеры использования

## 🎯 Сценарий 1: Настройка нового веб-сервера

### Шаг 1: Добавить сервер в inventory

```bash
# Редактируем inventory/production
nano inventory/production
```

Добавляем:
```ini
[webservers]
web4.example.com ansible_host=192.168.1.13
```

### Шаг 2: Проверяем доступность

```bash
ansible web4.example.com -i inventory/production -m ping
```

### Шаг 3: Базовая настройка

```bash
ansible-playbook -i inventory/production playbooks/site.yml \
  --limit web4.example.com \
  --tags common
```

### Шаг 4: Установка Nginx

```bash
ansible-playbook -i inventory/production playbooks/webservers.yml \
  --limit web4.example.com
```

### Шаг 5: Проверка

```bash
# Проверяем статус Nginx
ansible web4.example.com -i inventory/production -m systemd \
  -a "name=nginx state=started"

# Проверяем конфигурацию
ansible web4.example.com -i inventory/production -m shell \
  -a "nginx -t"
```

## 🎯 Сценарий 2: Деплой приложения

### Деплой на staging

```bash
ansible-playbook -i inventory/staging playbooks/deploy-app.yml \
  -e "version=v1.2.3"
```

### Деплой на production (rolling update)

```bash
# По одному серверу
ansible-playbook -i inventory/production playbooks/deploy-app.yml \
  -e "version=v1.2.3" \
  --check --diff  # Сначала dry-run

# Реальный деплой
ansible-playbook -i inventory/production playbooks/deploy-app.yml \
  -e "version=v1.2.3"
```

### Деплой только на конкретный сервер

```bash
ansible-playbook -i inventory/production playbooks/deploy-app.yml \
  -e "version=v1.2.3" \
  --limit web1.example.com
```

## 🎯 Сценарий 3: Обновление SSL сертификатов

### Создаем playbook

```yaml
# playbooks/update-ssl.yml
---
- hosts: webservers
  become: yes
  tasks:
    - name: Copy new SSL certificate
      copy:
        src: files/ssl/new-cert.crt
        dest: /etc/ssl/certs/example.com.crt
        mode: '0644'
      notify: reload nginx

    - name: Copy new SSL key
      copy:
        src: files/ssl/new-cert.key
        dest: /etc/ssl/private/example.com.key
        mode: '0600'
      notify: reload nginx
      no_log: true

  handlers:
    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
```

### Запускаем

```bash
ansible-playbook -i inventory/production playbooks/update-ssl.yml
```

## 🎯 Сценарий 4: Установка пакетов на всех серверах

### Ad-hoc команда

```bash
# Установить htop на все серверы
ansible all -i inventory/production -m apt \
  -a "name=htop state=present" \
  --become

# Обновить все пакеты
ansible all -i inventory/production -m apt \
  -a "update_cache=yes upgrade=dist" \
  --become
```

## 🎯 Сценарий 5: Создание резервной копии БД

### Вручную запустить backup

```bash
ansible databases -i inventory/production -m shell \
  -a "/usr/local/bin/pg_backup.sh" \
  --become --become-user=postgres
```

### Скачать backup на локальную машину

```bash
ansible db-primary.example.com -i inventory/production -m fetch \
  -a "src=/var/backups/postgresql/myapp_production_20240115_020000.sql.gz dest=/local/backups/ flat=yes"
```

## 🎯 Сценарий 6: Мониторинг состояния серверов

### Проверка свободного места

```bash
ansible all -i inventory/production -m shell \
  -a "df -h" \
  | grep -E "(Filesystem|/dev/)"
```

### Проверка памяти

```bash
ansible all -i inventory/production -m shell \
  -a "free -h"
```

### Проверка uptime

```bash
ansible all -i inventory/production -m shell \
  -a "uptime"
```

### Собрать все факты о серверах

```bash
ansible all -i inventory/production -m setup \
  --tree /tmp/facts
```

## 🎯 Сценарий 7: Управление пользователями

### Создать playbook для добавления пользователя

```yaml
# playbooks/add-user.yml
---
- hosts: all
  become: yes
  vars_prompt:
    - name: username
      prompt: "Enter username"
      private: no

    - name: ssh_key
      prompt: "Enter SSH public key"
      private: no

  tasks:
    - name: Create user
      user:
        name: "{{ username }}"
        groups: sudo
        shell: /bin/bash
        createhome: yes

    - name: Add SSH key
      authorized_key:
        user: "{{ username }}"
        key: "{{ ssh_key }}"
```

### Запуск

```bash
ansible-playbook -i inventory/production playbooks/add-user.yml
```

## 🎯 Сценарий 8: Обновление конфигурации

### Изменить переменную

```bash
# Редактируем group_vars/webservers.yml
nano group_vars/webservers.yml
```

Меняем:
```yaml
nginx_worker_processes: 4  # было: auto
```

### Применяем изменения

```bash
ansible-playbook -i inventory/production playbooks/webservers.yml \
  --tags config \
  --check --diff  # Смотрим что изменится

# Применяем
ansible-playbook -i inventory/production playbooks/webservers.yml \
  --tags config
```

## 🎯 Сценарий 9: Отладка проблем

### Проверить логи

```bash
# Последние 50 строк логов Nginx
ansible web1.example.com -i inventory/production -m shell \
  -a "tail -n 50 /var/log/nginx/error.log"

# Логи systemd для сервиса
ansible web1.example.com -i inventory/production -m shell \
  -a "journalctl -u nginx -n 100"
```

### Проверить переменные для хоста

```bash
ansible-inventory -i inventory/production --host web1.example.com
```

### Запустить playbook в debug режиме

```bash
ansible-playbook -i inventory/production playbooks/site.yml \
  --limit web1.example.com \
  -vvvv
```

### Step-by-step выполнение

```bash
ansible-playbook -i inventory/production playbooks/webservers.yml \
  --step
```

## 🎯 Сценарий 10: Массовые операции

### Перезагрузить все веб-серверы (по очереди)

```bash
# Создаем playbook
cat > playbooks/reboot-webservers.yml <<EOF
---
- hosts: webservers
  become: yes
  serial: 1
  tasks:
    - name: Reboot server
      reboot:
        reboot_timeout: 300

    - name: Wait for server to come back
      wait_for_connection:
        delay: 60
        timeout: 300
EOF

# Запускаем
ansible-playbook -i inventory/production playbooks/reboot-webservers.yml
```

### Остановить все приложения

```bash
ansible webservers -i inventory/production -m systemd \
  -a "name=myapp state=stopped" \
  --become
```

### Запустить все приложения

```bash
ansible webservers -i inventory/production -m systemd \
  -a "name=myapp state=started" \
  --become
```

## 🎯 Сценарий 11: Тестирование playbook

### Molecule тесты (для роли)

```bash
cd roles/webserver

# Создать тестовое окружение
molecule create

# Запустить playbook
molecule converge

# Запустить тесты
molecule verify

# Удалить тестовое окружение
molecule destroy

# Все в одной команде
molecule test
```

### Локальное тестирование с Vagrant

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/site.yml"
    ansible.inventory_path = "inventory/local"
  end
end
```

```bash
vagrant up
vagrant provision
```

## 🎯 Сценарий 12: Работа с динамическим inventory

### AWS EC2

```bash
# Установить плагин
pip install boto3 botocore

# Создать конфиг
cat > inventory/aws_ec2.yml <<EOF
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
EOF

# Использовать
ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml
```

## 📊 Полезные команды для повседневной работы

```bash
# Список всех хостов
ansible-inventory -i inventory/production --list

# График хостов
ansible-inventory -i inventory/production --graph

# Проверить синтаксис playbook
ansible-playbook playbooks/site.yml --syntax-check

# Список задач
ansible-playbook playbooks/site.yml --list-tasks

# Список тегов
ansible-playbook playbooks/site.yml --list-tags

# Список хостов для playbook
ansible-playbook playbooks/site.yml --list-hosts

# Dry-run с показом изменений
ansible-playbook playbooks/site.yml --check --diff

# Начать с конкретной задачи
ansible-playbook playbooks/site.yml --start-at-task="Install Nginx"

# Только задачи с тегом
ansible-playbook playbooks/site.yml --tags "nginx,ssl"

# Исключить теги
ansible-playbook playbooks/site.yml --skip-tags "backup"
```

## 🔒 Работа с Vault - практика

```bash
# Создать зашифрованный файл
ansible-vault create group_vars/production/vault.yml

# Добавить в него:
# vault_db_password: "super_secret_123"
# vault_api_key: "secret_key_456"

# Использовать в vars файле
# group_vars/production/vars.yml:
# db_password: "{{ vault_db_password }}"
# api_key: "{{ vault_api_key }}"

# Запустить playbook с vault
ansible-playbook -i inventory/production playbooks/site.yml \
  --ask-vault-pass

# Или с файлом пароля
echo "myVaultPassword" > .vault_pass
chmod 600 .vault_pass
ansible-playbook -i inventory/production playbooks/site.yml \
  --vault-password-file .vault_pass
```

## 🎓 Советы и трюки

### 1. Использовать callback плагин для красивого вывода

```ini
# ansible.cfg
[defaults]
stdout_callback = yaml
```

### 2. Увеличить скорость выполнения

```ini
# ansible.cfg
[defaults]
forks = 20
pipelining = True

[ssh_connection]
pipelining = True
```

### 3. Использовать --diff для всех playbooks

```ini
# ansible.cfg
[defaults]
diff_always = True
```

### 4. Сохранять вывод в файл

```bash
ansible-playbook playbooks/site.yml 2>&1 | tee deployment.log
```

### 5. Использовать роли из Galaxy

```bash
# requirements.yml
---
roles:
  - name: geerlingguy.nginx
  - name: geerlingguy.postgresql

# Установить
ansible-galaxy install -r requirements.yml

# Использовать в playbook
roles:
  - geerlingguy.nginx
```
