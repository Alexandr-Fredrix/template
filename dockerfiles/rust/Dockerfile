# Multi-stage build для Rust приложения
# Очень эффективная сборка с минимальным размером

# ============================================
# Стадия 1: Сборка
# ============================================
FROM rust:1.75-alpine AS builder

WORKDIR /app

# Устанавливаем системные зависимости для компиляции
RUN apk add --no-cache musl-dev

# Копируем Cargo файлы
COPY Cargo.toml Cargo.lock ./

# Создаем dummy main для кеширования зависимостей
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Копируем реальный код
COPY src ./src

# Собираем приложение
RUN cargo build --release

# ============================================
# Стадия 2: Runtime
# ============================================
FROM alpine:latest

# Устанавливаем runtime зависимости
RUN apk add --no-cache libgcc

# Создаем пользователя
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Копируем бинарник
COPY --from=builder --chown=appuser:appgroup /app/target/release/myapp .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./myapp"]
