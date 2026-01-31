# MySQL/MariaDB для DevOps

MySQL - самая популярная реляционная база данных с открытым исходным кодом.

## 🚀 Быстрый старт

### Запуск в Docker

```bash
cd docker/
docker-compose up -d
```

### Подключение

```bash
# Локальное подключение
mysql -u root -p

# Удалённое подключение
mysql -h hostname -u username -p database

# Выполнить SQL файл
mysql -u root -p database < script.sql
```

## 💡 Основные команды

### Управление базами данных

```sql
-- Список баз данных
SHOW DATABASES;

-- Создать базу
CREATE DATABASE myapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Удалить базу
DROP DATABASE myapp;

-- Использовать базу
USE myapp;

-- Показать таблицы
SHOW TABLES;

-- Описание таблицы
DESCRIBE users;
SHOW CREATE TABLE users;
```

### Управление пользователями

```sql
-- Создать пользователя
CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';
CREATE USER 'myuser'@'%' IDENTIFIED BY 'password';  -- Любой хост

-- Выдать права
GRANT ALL PRIVILEGES ON myapp.* TO 'myuser'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON myapp.* TO 'myuser'@'%';

-- Применить изменения
FLUSH PRIVILEGES;

-- Показать права
SHOW GRANTS FOR 'myuser'@'localhost';

-- Изменить пароль
ALTER USER 'myuser'@'localhost' IDENTIFIED BY 'new_password';

-- Удалить пользователя
DROP USER 'myuser'@'localhost';
```

### CRUD операции

```sql
-- CREATE
INSERT INTO users (name, email) VALUES ('John', 'john@example.com');

-- READ
SELECT * FROM users WHERE id = 1;

-- UPDATE
UPDATE users SET name = 'John Doe' WHERE id = 1;

-- DELETE
DELETE FROM users WHERE id = 1;

-- INSERT ... ON DUPLICATE KEY UPDATE (upsert)
INSERT INTO users (id, name, email) VALUES (1, 'John', 'john@example.com')
ON DUPLICATE KEY UPDATE name = VALUES(name), email = VALUES(email);
```

## 🔧 DevOps задачи

### Backup

```bash
# Backup одной базы
mysqldump -u root -p myapp > myapp_backup.sql

# С сжатием
mysqldump -u root -p myapp | gzip > myapp_backup.sql.gz

# Backup всех баз
mysqldump -u root -p --all-databases > all_databases.sql

# Backup структуры без данных
mysqldump -u root -p --no-data myapp > myapp_schema.sql

# Backup только данных
mysqldump -u root -p --no-create-info myapp > myapp_data.sql

# Использовать готовый скрипт
./scripts/backup-mysql.sh
```

### Restore

```bash
# Restore из SQL файла
mysql -u root -p myapp < myapp_backup.sql

# Restore из сжатого файла
gunzip < myapp_backup.sql.gz | mysql -u root -p myapp

# Restore всех баз
mysql -u root -p < all_databases.sql

# Использовать готовый скрипт
./scripts/restore-mysql.sh myapp_backup.sql
```

### Мониторинг

```sql
-- Показать процессы
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Убить процесс
KILL 12345;

-- Статус сервера
SHOW STATUS;
SHOW GLOBAL STATUS LIKE 'Threads%';
SHOW GLOBAL STATUS LIKE 'Questions';

-- Переменные
SHOW VARIABLES;
SHOW VARIABLES LIKE 'max_connections';

-- Размер баз данных
SELECT table_schema AS "Database",
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)"
FROM information_schema.TABLES
GROUP BY table_schema;

-- Размер таблиц
SELECT table_name AS "Table",
       ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES
WHERE table_schema = "myapp"
ORDER BY (data_length + index_length) DESC;

-- Медленные запросы
SHOW VARIABLES LIKE 'slow_query_log%';
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
```

## 🔒 Безопасность

```sql
-- Создать read-only пользователя
CREATE USER 'readonly'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON myapp.* TO 'readonly'@'%';

-- Создать пользователя для приложения
CREATE USER 'app_user'@'%' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON myapp.* TO 'app_user'@'%';

-- Ограничить по IP
CREATE USER 'admin'@'192.168.1.%' IDENTIFIED BY 'password';

-- SSL подключение
GRANT ALL PRIVILEGES ON myapp.* TO 'secure_user'@'%'
IDENTIFIED BY 'password' REQUIRE SSL;
```

## 📊 Performance Tuning

### Ключевые параметры my.cnf

```ini
[mysqld]
# General
max_connections = 150
max_allowed_packet = 64M

# InnoDB
innodb_buffer_pool_size = 1G          # 70-80% от RAM
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2    # Для производительности
innodb_flush_method = O_DIRECT

# Query Cache (deprecated в MySQL 8.0)
# query_cache_type = 1
# query_cache_size = 64M

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Binary Logging (для репликации)
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
expire_logs_days = 7
```

### Оптимизация таблиц

```sql
-- Анализ таблицы
ANALYZE TABLE users;

-- Оптимизация таблицы
OPTIMIZE TABLE users;

-- Проверка таблицы
CHECK TABLE users;

-- Починка таблицы
REPAIR TABLE users;

-- EXPLAIN запроса
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```

## 🔄 Репликация

### Master настройка

```ini
# my.cnf
[mysqld]
server-id = 1
log_bin = mysql-bin
binlog_do_db = myapp
```

```sql
-- Создать пользователя для репликации
CREATE USER 'replicator'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;

-- Получить позицию master
SHOW MASTER STATUS;
```

### Slave настройка

```ini
# my.cnf
[mysqld]
server-id = 2
relay-log = mysql-relay-bin
```

```sql
-- Настроить slave
CHANGE MASTER TO
    MASTER_HOST='master_host',
    MASTER_USER='replicator',
    MASTER_PASSWORD='password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=12345;

-- Запустить репликацию
START SLAVE;

-- Проверить статус
SHOW SLAVE STATUS\G
```

## 🔍 Troubleshooting

```sql
-- Проверить подключение
SELECT 1;

-- Версия MySQL
SELECT VERSION();

-- Uptime
SHOW GLOBAL STATUS LIKE 'Uptime';

-- Блокировки
SHOW OPEN TABLES WHERE In_use > 0;

-- Проверить права
SELECT user, host FROM mysql.user;

-- Проверить лог ошибок
-- /var/log/mysql/error.log
```

## 🎯 Чек-лист для Production

- [ ] Настроен регулярный backup
- [ ] Настроена репликация
- [ ] Настроен мониторинг
- [ ] Включено логирование медленных запросов
- [ ] Настроены алерты
- [ ] Протестирован disaster recovery
- [ ] Созданы пользователи с минимальными правами
- [ ] Настроен SSL
- [ ] Ограничен доступ по IP
- [ ] Настроены ресурсы (buffer pool, connections)
- [ ] Удалены тестовые базы и пользователи
- [ ] Изменён пароль root

## 📚 Дополнительно

- [Подробные команды](commands.md)
- [Backup и Restore](backup-restore.md)
- [Мониторинг](monitoring.md)
- [Скрипты автоматизации](scripts/)
