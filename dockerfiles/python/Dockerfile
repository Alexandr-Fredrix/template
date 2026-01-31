# Multi-stage build для Python приложения

# ============================================
# Стадия 1: Builder (установка зависимостей)
# ============================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Устанавливаем системные зависимости для компиляции Python пакетов
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Создаем виртуальное окружение
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем requirements
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ============================================
# Стадия 2: Runtime
# ============================================
FROM python:3.11-slim AS runtime

WORKDIR /app

# Создаем пользователя
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Копируем виртуальное окружение
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv

# Копируем приложение
COPY --chown=appuser:appuser . .

# Активируем виртуальное окружение
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Запуск приложения
CMD ["python", "app.py"]
