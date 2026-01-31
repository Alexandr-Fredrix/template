# Multi-stage build для Node.js приложения
# Оптимизирован для production использования

# ============================================
# Стадия 1: Зависимости
# ============================================
FROM node:18-alpine AS deps
WORKDIR /app

# Копируем файлы package для кеширования зависимостей
COPY package.json package-lock.json* ./

# Устанавливаем только production зависимости
RUN npm ci --only=production && \
    npm cache clean --force

# ============================================
# Стадия 2: Сборка (если нужна)
# ============================================
FROM node:18-alpine AS builder
WORKDIR /app

# Копируем все файлы package
COPY package.json package-lock.json* ./

# Устанавливаем все зависимости (включая dev)
RUN npm ci

# Копируем исходный код
COPY . .

# Сборка приложения (раскомментируйте если нужно)
# RUN npm run build

# ============================================
# Стадия 3: Production образ
# ============================================
FROM node:18-alpine AS runner
WORKDIR /app

# Добавляем пользователя для безопасности
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Копируем зависимости из стадии deps
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Копируем собранное приложение
COPY --from=builder --chown=nodejs:nodejs /app .

# Переменные окружения
ENV NODE_ENV=production \
    PORT=3000

# Переключаемся на непривилегированного пользователя
USER nodejs

# Открываем порт
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js

# Запуск приложения
CMD ["node", "index.js"]
