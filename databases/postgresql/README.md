# PostgreSQL для DevOps

PostgreSQL - мощная объектно-реляционная система управления базами данных с открытым исходным кодом.

## 📚 Содержание

- [Установка и настройка](installation.md)
- [Команды и работа с БД](commands.md)
- [Backup и Restore](backup-restore.md)
- [Мониторинг](monitoring.md)

## 🚀 Быстрый старт

### Запуск в Docker

```bash
cd docker/
docker-compose up -d
```

### Подключение

```bash
# Подключение к БД
psql -h localhost -U postgres -d postgres

# Или через Docker
docker exec -it postgres_container psql -U postgres
```

### Создание базы и пользователя

```sql
-- Создать базу данных
CREATE DATABASE myapp;

-- Создать пользователя
CREATE USER myapp_user WITH ENCRYPTED PASSWORD 'secure_password';

-- Выдать права
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;
```

## 💡 Основные команды

### Работа с базами

```sql
-- Список баз данных
\l

-- Подключиться к базе
\c myapp

-- Список таблиц
\dt

-- Описание таблицы
\d table_name

-- Список пользователей
\du
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
```

## 🔧 DevOps задачи

### 1. Backup базы данных

```bash
# Backup одной базы
pg_dump -h localhost -U postgres myapp > myapp_backup.sql

# Backup с сжатием
pg_dump -h localhost -U postgres myapp | gzip > myapp_backup.sql.gz

# Backup всех баз
pg_dumpall -h localhost -U postgres > all_databases.sql

# Использовать готовый скрипт
./scripts/backup-postgres.sh
```

### 2. Restore базы данных

```bash
# Restore из SQL файла
psql -h localhost -U postgres myapp < myapp_backup.sql

# Restore из сжатого файла
gunzip < myapp_backup.sql.gz | psql -h localhost -U postgres myapp

# Использовать готовый скрипт
./scripts/restore-postgres.sh myapp_backup.sql
```

### 3. Health Check

```bash
# Проверка доступности
pg_isready -h localhost -U postgres

# Использовать готовый скрипт
./scripts/health-check.sh
```

### 4. Мониторинг

```sql
-- Активные подключения
SELECT count(*) FROM pg_stat_activity;

-- Медленные запросы
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

-- Размер баз данных
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;

-- Размер таблиц
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

## 🔒 Безопасность

### 1. Создание пользователей с ограниченными правами

```sql
-- Создать read-only пользователя
CREATE USER readonly WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE myapp TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;

-- Создать пользователя для приложения
CREATE USER app_user WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE myapp TO app_user;
GRANT USAGE, CREATE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
```

### 2. Настройка pg_hba.conf

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
host    all             all             10.0.0.0/8              md5

# IPv6 local connections:
host    all             all             ::1/128                 md5

# Reject all other connections
host    all             all             0.0.0.0/0               reject
```

### 3. SSL соединение

```bash
# Подключение с SSL
psql "postgresql://user:password@localhost:5432/myapp?sslmode=require"
```

## 📊 Performance Tuning

### Ключевые параметры postgresql.conf

```conf
# Memory
shared_buffers = 256MB                # 25% от RAM
effective_cache_size = 1GB            # 50-75% от RAM
work_mem = 4MB                        # RAM / max_connections / 4

# Connections
max_connections = 100
superuser_reserved_connections = 3

# Write-Ahead Log
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# Checkpoints
checkpoint_completion_target = 0.9
checkpoint_timeout = 10min

# Query Planner
random_page_cost = 1.1                # для SSD
effective_io_concurrency = 200        # для SSD

# Logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'                 # ddl, mod, all
log_duration = on
log_min_duration_statement = 1000     # медленные запросы > 1s
```

## 🔄 Репликация

### Master настройка

```conf
# postgresql.conf
wal_level = replica
max_wal_senders = 3
wal_keep_size = 64

# pg_hba.conf
host    replication     replicator      10.0.0.0/8              md5
```

```sql
-- Создать пользователя для репликации
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'password';
```

### Slave настройка

```bash
# Создать standby
pg_basebackup -h master_host -D /var/lib/postgresql/data -U replicator -P --wal-method=stream

# standby.signal
touch /var/lib/postgresql/data/standby.signal

# postgresql.auto.conf
primary_conninfo = 'host=master_host port=5432 user=replicator password=password'
```

## 🔍 Troubleshooting

### Проблемы с подключением

```bash
# Проверить, запущен ли PostgreSQL
systemctl status postgresql

# Проверить, слушает ли порт
netstat -tlnp | grep 5432

# Проверить логи
tail -f /var/log/postgresql/postgresql-*.log
```

### Медленные запросы

```sql
-- Включить расширение pg_stat_statements
CREATE EXTENSION pg_stat_statements;

-- Топ медленных запросов
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Анализ запроса
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

### Блокировки

```sql
-- Активные блокировки
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Убить блокирующую сессию
SELECT pg_terminate_backend(pid);
```

## 📦 Полезные расширения

```sql
-- UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PostGIS (географические данные)
CREATE EXTENSION IF NOT EXISTS postgis;

-- pg_stat_statements (статистика запросов)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- pg_trgm (полнотекстовый поиск)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- hstore (key-value хранилище)
CREATE EXTENSION IF NOT EXISTS hstore;
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
- [ ] Настроены ресурсы (shared_buffers, work_mem)
- [ ] Настроена автоочистка (autovacuum)
- [ ] Документированы процедуры восстановления

## 📚 Дополнительные материалы

- [Подробные команды](commands.md)
- [Backup и Restore](backup-restore.md)
- [Мониторинг](monitoring.md)
- [Скрипты автоматизации](scripts/)
