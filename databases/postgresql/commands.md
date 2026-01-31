# PostgreSQL - Команды и примеры

Полный справочник команд PostgreSQL для DevOps инженеров.

## 📚 Содержание

- [Подключение](#подключение)
- [Управление базами данных](#управление-базами-данных)
- [Управление пользователями](#управление-пользователями)
- [Работа с таблицами](#работа-с-таблицами)
- [CRUD операции](#crud-операции)
- [Индексы](#индексы)
- [Транзакции](#транзакции)
- [Мониторинг](#мониторинг)
- [Maintenance](#maintenance)

## Подключение

### Базовое подключение

```bash
# Локальное подключение
psql -U postgres

# Подключение к конкретной БД
psql -U postgres -d myapp

# Удалённое подключение
psql -h hostname -p 5432 -U username -d database

# С паролем в переменной окружения
PGPASSWORD=password psql -h hostname -U username -d database

# Connection string
psql "postgresql://username:password@hostname:5432/database"

# С SSL
psql "postgresql://username:password@hostname:5432/database?sslmode=require"
```

### Psql мета-команды

```sql
-- Помощь
\?                          -- Помощь по psql командам
\h                          -- Помощь по SQL командам
\h CREATE TABLE             -- Помощь по конкретной команде

-- Навигация
\l                          -- Список баз данных
\c database_name            -- Подключиться к БД
\dt                         -- Список таблиц
\dt+                        -- Список таблиц с размерами
\d table_name               -- Описание таблицы
\d+ table_name              -- Детальное описание
\dn                         -- Список схем
\du                         -- Список пользователей
\df                         -- Список функций
\dv                         -- Список view
\di                         -- Список индексов

-- Выполнение
\i file.sql                 -- Выполнить SQL из файла
\o output.txt               -- Перенаправить вывод в файл
\! command                  -- Выполнить shell команду

-- Настройки
\timing                     -- Показывать время выполнения
\x                          -- Расширенный вывод (вертикально)
\pset pager off             -- Отключить пагинацию

-- Выход
\q                          -- Выход
```

## Управление базами данных

### Создание и удаление

```sql
-- Создать базу данных
CREATE DATABASE myapp;

-- С параметрами
CREATE DATABASE myapp
    WITH OWNER = myapp_user
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Создать из шаблона
CREATE DATABASE test_db WITH TEMPLATE myapp;

-- Удалить базу данных
DROP DATABASE myapp;

-- Удалить с принудительным отключением
DROP DATABASE myapp WITH (FORCE);

-- Переименовать
ALTER DATABASE myapp RENAME TO myapp_new;

-- Изменить owner
ALTER DATABASE myapp OWNER TO new_owner;
```

### Информация о базах

```sql
-- Список баз данных
SELECT datname, pg_size_pretty(pg_database_size(datname))
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Детальная информация
SELECT *
FROM pg_database
WHERE datname = 'myapp';

-- Количество подключений
SELECT datname, count(*)
FROM pg_stat_activity
GROUP BY datname;
```

## Управление пользователями

### Создание пользователей

```sql
-- Создать пользователя
CREATE USER myuser WITH PASSWORD 'secure_password';

-- С дополнительными параметрами
CREATE USER myuser WITH
    PASSWORD 'secure_password'
    CREATEDB
    CREATEROLE
    VALID UNTIL '2025-12-31';

-- Создать суперпользователя
CREATE USER admin WITH SUPERUSER PASSWORD 'admin_password';

-- Изменить пароль
ALTER USER myuser WITH PASSWORD 'new_password';

-- Переименовать
ALTER USER myuser RENAME TO myuser_new;

-- Удалить пользователя
DROP USER myuser;
```

### Управление правами

```sql
-- Выдать все права на БД
GRANT ALL PRIVILEGES ON DATABASE myapp TO myuser;

-- Выдать права на схему
GRANT USAGE ON SCHEMA public TO myuser;
GRANT CREATE ON SCHEMA public TO myuser;

-- Выдать права на таблицы
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO myuser;

-- Выдать права на последовательности
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO myuser;

-- Права по умолчанию для новых объектов
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO myuser;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO myuser;

-- Забрать права
REVOKE ALL PRIVILEGES ON DATABASE myapp FROM myuser;

-- Read-only пользователь
GRANT CONNECT ON DATABASE myapp TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;

-- Список прав
\dp tablename               -- Права на таблицу
SELECT * FROM information_schema.table_privileges WHERE grantee = 'myuser';
```

## Работа с таблицами

### Создание таблиц

```sql
-- Простая таблица
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- С внешними ключами
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- С check constraint
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) CHECK (price > 0),
    quantity INTEGER CHECK (quantity >= 0)
);

-- Партиционированная таблица
CREATE TABLE measurements (
    city_id INT NOT NULL,
    logdate DATE NOT NULL,
    peaktemp INT,
    unitsales INT
) PARTITION BY RANGE (logdate);

CREATE TABLE measurements_y2024m01 PARTITION OF measurements
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### Изменение таблиц

```sql
-- Добавить колонку
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Удалить колонку
ALTER TABLE users DROP COLUMN phone;

-- Изменить тип колонки
ALTER TABLE users ALTER COLUMN username TYPE VARCHAR(100);

-- Переименовать колонку
ALTER TABLE users RENAME COLUMN username TO login;

-- Добавить NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- Убрать NOT NULL
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Добавить значение по умолчанию
ALTER TABLE users ALTER COLUMN created_at SET DEFAULT NOW();

-- Добавить constraint
ALTER TABLE users ADD CONSTRAINT users_email_check CHECK (email LIKE '%@%');

-- Удалить constraint
ALTER TABLE users DROP CONSTRAINT users_email_check;

-- Переименовать таблицу
ALTER TABLE users RENAME TO app_users;
```

### Удаление таблиц

```sql
-- Удалить таблицу
DROP TABLE users;

-- С каскадным удалением
DROP TABLE users CASCADE;

-- Если существует
DROP TABLE IF EXISTS users;

-- Очистить таблицу
TRUNCATE TABLE users;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
```

## CRUD операции

### INSERT

```sql
-- Вставить одну запись
INSERT INTO users (username, email)
VALUES ('john', 'john@example.com');

-- Вставить несколько записей
INSERT INTO users (username, email) VALUES
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com'),
    ('charlie', 'charlie@example.com');

-- С возвратом ID
INSERT INTO users (username, email)
VALUES ('dave', 'dave@example.com')
RETURNING id;

-- Вставить из SELECT
INSERT INTO users_archive
SELECT * FROM users WHERE created_at < '2023-01-01';

-- ON CONFLICT (upsert)
INSERT INTO users (username, email)
VALUES ('john', 'john@example.com')
ON CONFLICT (username)
DO UPDATE SET email = EXCLUDED.email;

-- ON CONFLICT DO NOTHING
INSERT INTO users (username, email)
VALUES ('john', 'john@example.com')
ON CONFLICT (username) DO NOTHING;
```

### SELECT

```sql
-- Простой SELECT
SELECT * FROM users;

-- Конкретные колонки
SELECT id, username, email FROM users;

-- С условием
SELECT * FROM users WHERE id = 1;

-- С несколькими условиями
SELECT * FROM users
WHERE created_at > '2024-01-01'
  AND email LIKE '%@gmail.com';

-- Сортировка
SELECT * FROM users ORDER BY created_at DESC;

-- Ограничение результатов
SELECT * FROM users LIMIT 10;
SELECT * FROM users LIMIT 10 OFFSET 20;  -- Пагинация

-- Агрегация
SELECT COUNT(*) FROM users;
SELECT COUNT(*), MAX(id), MIN(id), AVG(id) FROM users;

-- GROUP BY
SELECT email, COUNT(*)
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- JOIN
SELECT u.username, p.title
FROM users u
INNER JOIN posts p ON u.id = p.user_id;

-- LEFT JOIN
SELECT u.username, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.username;

-- WITH (CTE)
WITH active_users AS (
    SELECT * FROM users WHERE created_at > '2024-01-01'
)
SELECT * FROM active_users WHERE email LIKE '%@gmail.com';

-- DISTINCT
SELECT DISTINCT email FROM users;

-- LIKE
SELECT * FROM users WHERE username LIKE 'john%';
SELECT * FROM users WHERE email ILIKE '%GMAIL.COM';  -- case-insensitive
```

### UPDATE

```sql
-- Обновить одну запись
UPDATE users SET email = 'newemail@example.com' WHERE id = 1;

-- Обновить несколько полей
UPDATE users
SET email = 'new@example.com',
    updated_at = NOW()
WHERE id = 1;

-- Обновить все записи
UPDATE users SET updated_at = NOW();

-- С подзапросом
UPDATE users
SET email = (SELECT email FROM users_temp WHERE users_temp.id = users.id)
WHERE EXISTS (SELECT 1 FROM users_temp WHERE users_temp.id = users.id);

-- С RETURNING
UPDATE users
SET email = 'new@example.com'
WHERE id = 1
RETURNING *;
```

### DELETE

```sql
-- Удалить одну запись
DELETE FROM users WHERE id = 1;

-- Удалить по условию
DELETE FROM users WHERE created_at < '2023-01-01';

-- Удалить все записи
DELETE FROM users;

-- С RETURNING
DELETE FROM users WHERE id = 1 RETURNING *;

-- Каскадное удаление через JOIN
DELETE FROM posts
WHERE user_id IN (SELECT id FROM users WHERE created_at < '2023-01-01');
```

## Индексы

### Создание индексов

```sql
-- Простой индекс
CREATE INDEX idx_users_email ON users(email);

-- Уникальный индекс
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- Композитный индекс
CREATE INDEX idx_users_name_email ON users(username, email);

-- Частичный индекс
CREATE INDEX idx_active_users ON users(username)
WHERE deleted_at IS NULL;

-- B-tree индекс (по умолчанию)
CREATE INDEX idx_users_id ON users USING btree(id);

-- Hash индекс
CREATE INDEX idx_users_email_hash ON users USING hash(email);

-- GIN индекс (для JSON, массивов)
CREATE INDEX idx_users_metadata ON users USING gin(metadata);

-- Создать индекс в фоне (не блокирует таблицу)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

### Управление индексами

```sql
-- Список индексов
\di

-- Детальная информация
SELECT * FROM pg_indexes WHERE tablename = 'users';

-- Размер индексов
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;

-- Неиспользуемые индексы
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelid NOT IN (
    SELECT indexrelid FROM pg_index WHERE indisunique OR indisprimary
)
ORDER BY pg_relation_size(indexrelid) DESC;

-- Удалить индекс
DROP INDEX idx_users_email;

-- Удалить в фоне
DROP INDEX CONCURRENTLY idx_users_email;

-- Перестроить индекс
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## Транзакции

```sql
-- Начать транзакцию
BEGIN;
-- или
START TRANSACTION;

-- Выполнить операции
INSERT INTO users (username, email) VALUES ('test', 'test@example.com');
UPDATE posts SET user_id = 1 WHERE id = 100;

-- Подтвердить
COMMIT;

-- Или отменить
ROLLBACK;

-- С точкой сохранения
BEGIN;
INSERT INTO users (username, email) VALUES ('test1', 'test1@example.com');
SAVEPOINT my_savepoint;
INSERT INTO users (username, email) VALUES ('test2', 'test2@example.com');
ROLLBACK TO SAVEPOINT my_savepoint;  -- Откатить до точки
COMMIT;

-- Уровни изоляции
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

## Мониторинг

### Активность

```sql
-- Текущие подключения
SELECT count(*) FROM pg_stat_activity;

-- Детальная информация о подключениях
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Долгие запросы
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Убить процесс
SELECT pg_terminate_backend(pid);
SELECT pg_cancel_backend(pid);  -- Мягкая отмена
```

### Статистика

```sql
-- Статистика по таблицам
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- Статистика по индексам
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Cache hit ratio
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit)  as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM pg_statio_user_tables;
```

## Maintenance

### VACUUM

```sql
-- VACUUM таблицы
VACUUM users;

-- VACUUM с анализом
VACUUM ANALYZE users;

-- FULL VACUUM (блокирует таблицу)
VACUUM FULL users;

-- VACUUM всей базы
VACUUM;

-- Проверить необходимость VACUUM
SELECT schemaname, tablename, n_dead_tup, n_live_tup,
       round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;
```

### ANALYZE

```sql
-- Обновить статистику
ANALYZE users;
ANALYZE;

-- С verbose
ANALYZE VERBOSE users;
```

### REINDEX

```sql
-- Перестроить индексы таблицы
REINDEX TABLE users;

-- Перестроить конкретный индекс
REINDEX INDEX idx_users_email;

-- Перестроить все индексы БД
REINDEX DATABASE myapp;
```

## Полезные запросы для DevOps

```sql
-- Размер базы данных
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Топ 10 больших таблиц
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Блокировки
SELECT locktype, relation::regclass, mode, transactionid AS tid,
       virtualtransaction AS vtid, pid, granted
FROM pg_catalog.pg_locks
WHERE NOT granted;

-- Репликация
SELECT * FROM pg_stat_replication;

-- Версия PostgreSQL
SELECT version();

-- Uptime
SELECT pg_postmaster_start_time(),
       now() - pg_postmaster_start_time() AS uptime;

-- Конфигурация
SHOW all;
SHOW shared_buffers;
SHOW work_mem;
```
