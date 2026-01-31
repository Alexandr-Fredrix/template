# Multi-stage build для Go приложения
# Очень эффективная сборка с минимальным размером образа

# ============================================
# Стадия 1: Сборка
# ============================================
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копируем go mod файлы
COPY go.mod go.sum ./

# Скачиваем зависимости
RUN go mod download

# Копируем исходный код
COPY . .

# Компилируем статический бинарник
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o /app/main .

# ============================================
# Стадия 2: Minimal runtime (Scratch или Alpine)
# ============================================
# Вариант 1: Scratch (минимальный размер ~5-10MB)
FROM scratch AS runtime-scratch

# Копируем CA сертификаты для HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Копируем бинарник
COPY --from=builder /app/main /main

EXPOSE 8080

ENTRYPOINT ["/main"]

# ============================================
# Вариант 2: Alpine (если нужен shell и утилиты)
# ============================================
FROM alpine:latest AS runtime-alpine

# Добавляем CA сертификаты
RUN apk --no-cache add ca-certificates tzdata

# Создаем пользователя
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Копируем бинарник
COPY --from=builder --chown=appuser:appgroup /app/main .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["./main"]

# ============================================
# Используйте нужный stage:
# docker build --target runtime-scratch -t app:scratch .
# docker build --target runtime-alpine -t app:alpine .
# ============================================
