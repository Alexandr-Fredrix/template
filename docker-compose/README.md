# Docker Compose - Руководство и Шаблоны

## 📖 Что такое Docker Compose?

Docker Compose - это инструмент для определения и запуска многоконтейнерных Docker приложений. С помощью YAML файла вы описываете все сервисы вашего приложения, а затем запускаете их одной командой.

## 🏗️ Базовая структура docker-compose.yml

```yaml
version: '3.8'

services:
  # Определение сервисов
  app:
    image: nginx:alpine
    ports:
      - "80:80"

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret

volumes:
  # Определение volumes
  db_data:

networks:
  # Определение networks
  app_network:
```

## 📋 Основные секции

### Services
Определение контейнеров:
```yaml
services:
  web:
    image: nginx:latest           # Готовый образ
    build: ./app                  # Или сборка из Dockerfile
    container_name: my-web        # Имя контейнера
    restart: always               # Политика перезапуска
    ports:
      - "8080:80"                 # Проброс портов
    environment:                  # Переменные окружения
      - DEBUG=true
    volumes:                      # Монтирование
      - ./data:/data
    depends_on:                   # Зависимости
      - db
    networks:                     # Сети
      - frontend
```

### Volumes
Постоянное хранилище данных:
```yaml
volumes:
  db_data:                        # Именованный volume
  app_logs:
    driver: local
    driver_opts:
      type: none
      device: /path/on/host
      o: bind
```

### Networks
Изоляция сервисов:
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true                # Внутренняя сеть
```

## 🎯 Основные команды

```bash
# Запустить все сервисы
docker-compose up

# Запустить в фоне
docker-compose up -d

# Остановить сервисы
docker-compose down

# Остановить и удалить volumes
docker-compose down -v

# Пересобрать образы
docker-compose build

# Пересобрать и запустить
docker-compose up --build

# Посмотреть логи
docker-compose logs -f

# Логи конкретного сервиса
docker-compose logs -f service-name

# Посмотреть запущенные контейнеры
docker-compose ps

# Выполнить команду в контейнере
docker-compose exec service-name bash

# Масштабировать сервис
docker-compose up --scale web=3

# Валидация файла
docker-compose config

# Остановить без удаления
docker-compose stop

# Запустить остановленные контейнеры
docker-compose start

# Перезапустить сервис
docker-compose restart service-name
```

## 💡 Best Practices

### 1. Используйте .env файл
```bash
# .env
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret123
APP_PORT=8080
```

```yaml
# docker-compose.yml
services:
  db:
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  app:
    ports:
      - "${APP_PORT}:8080"
```

### 2. Используйте именованные volumes
✅ **Хорошо:**
```yaml
volumes:
  postgres_data:

services:
  db:
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

❌ **Плохо:**
```yaml
services:
  db:
    volumes:
      - /var/lib/postgresql/data  # Анонимный volume
```

### 3. Задавайте health checks
```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

### 4. Используйте depends_on с condition
```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy

  db:
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 5s
```

### 5. Ограничивайте ресурсы
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 6. Используйте profiles для разных окружений
```yaml
services:
  app:
    profiles: ["development", "production"]

  debug-tools:
    profiles: ["development"]
```

```bash
# Запуск только production сервисов
docker-compose --profile production up
```

## 🔧 Переменные и подстановки

### Переменные окружения
```yaml
services:
  web:
    image: "webapp:${TAG:-latest}"  # По умолчанию latest
    environment:
      - DEBUG=${DEBUG}
      - API_KEY=${API_KEY:?API_KEY must be set}  # Обязательная
```

### Использование extend
```yaml
# common-services.yml
services:
  base-app:
    environment:
      - LOG_LEVEL=info
    restart: unless-stopped

# docker-compose.yml
services:
  my-app:
    extends:
      file: common-services.yml
      service: base-app
    image: my-app:latest
```

## 🔍 Отладка

```bash
# Проверить конфигурацию
docker-compose config

# Посмотреть переменные окружения
docker-compose config --services

# Посмотреть итоговую конфигурацию сервиса
docker-compose config --services app

# Валидация без запуска
docker-compose up --dry-run

# Посмотреть события
docker-compose events

# Статистика использования ресурсов
docker stats
```

## 🔒 Безопасность

### 1. Не храните секреты в docker-compose.yml
✅ **Используйте secrets:**
```yaml
services:
  db:
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### 2. Используйте read-only volumes
```yaml
services:
  app:
    volumes:
      - ./config:/etc/config:ro  # read-only
```

### 3. Ограничивайте capabilities
```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

## 📦 Override файлы

Базовый `docker-compose.yml`:
```yaml
services:
  app:
    image: my-app:latest
    ports:
      - "8080:8080"
```

Development override `docker-compose.override.yml`:
```yaml
services:
  app:
    build: .
    volumes:
      - ./src:/app/src  # Hot reload
    environment:
      - DEBUG=true
```

Production override `docker-compose.prod.yml`:
```yaml
services:
  app:
    restart: always
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

```bash
# Использование override файлов
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 📚 Полезные ссылки

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Best practices](https://docs.docker.com/compose/production/)
