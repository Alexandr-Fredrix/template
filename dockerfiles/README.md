# Dockerfiles - Руководство и Шаблоны

## 📖 Что такое Dockerfile?

Dockerfile - это текстовый файл с инструкциями для сборки Docker образа. Он содержит все команды, необходимые для создания образа контейнера.

## 🏗️ Базовая структура Dockerfile

```dockerfile
# Базовый образ
FROM ubuntu:22.04

# Метаданные
LABEL maintainer="your.email@example.com"
LABEL version="1.0"
LABEL description="Description of your application"

# Аргументы сборки
ARG BUILD_DATE
ARG VERSION=1.0

# Переменные окружения
ENV APP_HOME=/app \
    APP_USER=appuser

# Установка зависимостей системы
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя (безопасность!)
RUN useradd -m -u 1000 -s /bin/bash ${APP_USER}

# Рабочая директория
WORKDIR ${APP_HOME}

# Копирование файлов
COPY --chown=${APP_USER}:${APP_USER} . .

# Установка зависимостей приложения
RUN ./install-dependencies.sh

# Переключение на непривилегированного пользователя
USER ${APP_USER}

# Открытие порта
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Команда запуска
CMD ["./start-app.sh"]
```

## 📋 Основные инструкции

### FROM
Базовый образ для сборки:
```dockerfile
FROM ubuntu:22.04
FROM node:18-alpine
FROM python:3.11-slim
```

### RUN
Выполнение команд при сборке:
```dockerfile
RUN apt-get update && apt-get install -y curl
RUN npm install
RUN pip install -r requirements.txt
```

### COPY и ADD
Копирование файлов:
```dockerfile
COPY package.json .
COPY --chown=user:user . /app
ADD https://example.com/file.tar.gz /tmp/
```

### WORKDIR
Рабочая директория:
```dockerfile
WORKDIR /app
```

### ENV
Переменные окружения:
```dockerfile
ENV NODE_ENV=production
ENV DATABASE_URL=postgresql://localhost/db
```

### EXPOSE
Документирование портов:
```dockerfile
EXPOSE 8080
EXPOSE 443
```

### USER
Пользователь для запуска:
```dockerfile
USER appuser
```

### CMD и ENTRYPOINT
Команда запуска:
```dockerfile
CMD ["python", "app.py"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--config", "/etc/config.yaml"]
```

## 🎯 Multi-stage builds

Уменьшение размера образа:

```dockerfile
# Стадия сборки
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Стадия production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
CMD ["node", "dist/index.js"]
```

## 💡 Best Practices

### 1. Используйте .dockerignore
```
node_modules
.git
.env
*.md
test/
.dockerignore
Dockerfile
```

### 2. Минимизируйте количество слоев
❌ **Плохо:**
```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
```

✅ **Хорошо:**
```dockerfile
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
```

### 3. Используйте конкретные версии
❌ **Плохо:**
```dockerfile
FROM node:latest
```

✅ **Хорошо:**
```dockerfile
FROM node:18.17.1-alpine
```

### 4. Копируйте только необходимое
✅ **Хорошо:**
```dockerfile
# Сначала зависимости (кешируются)
COPY package*.json ./
RUN npm ci

# Потом код (часто меняется)
COPY . .
```

### 5. Не запускайте от root
✅ **Хорошо:**
```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```

### 6. Используйте HEALTHCHECK
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

### 7. Используйте Alpine образы
```dockerfile
FROM node:18-alpine  # Вместо node:18 (меньше размер)
```

## 🔧 Сборка и запуск

```bash
# Сборка образа
docker build -t my-app:1.0 .

# Сборка с аргументами
docker build --build-arg VERSION=2.0 -t my-app:2.0 .

# Запуск контейнера
docker run -d -p 8080:8080 --name my-app my-app:1.0

# Посмотреть логи
docker logs my-app

# Зайти в контейнер
docker exec -it my-app /bin/sh

# Остановить и удалить
docker stop my-app
docker rm my-app

# Очистка
docker system prune -a
```

## 🔍 Отладка

```bash
# Посмотреть историю слоев
docker history my-app:1.0

# Инспектировать образ
docker inspect my-app:1.0

# Запустить с override CMD
docker run -it my-app:1.0 /bin/bash

# Посмотреть размер слоев
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

## 📦 Публикация

```bash
# Залогиниться в registry
docker login registry.example.com

# Тегировать образ
docker tag my-app:1.0 registry.example.com/my-app:1.0

# Отправить в registry
docker push registry.example.com/my-app:1.0

# Для Docker Hub
docker tag my-app:1.0 username/my-app:1.0
docker push username/my-app:1.0
```

## 🔒 Безопасность

1. **Сканирование уязвимостей**
```bash
docker scan my-app:1.0
trivy image my-app:1.0
```

2. **Не храните секреты в образе**
```dockerfile
# ❌ Плохо
ENV DATABASE_PASSWORD=secret123

# ✅ Хорошо - передавайте через переменные окружения
docker run -e DATABASE_PASSWORD=secret123 my-app
```

3. **Используйте distroless/minimal образы**
```dockerfile
FROM gcr.io/distroless/base-debian11
```

## 📚 Полезные ссылки

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
