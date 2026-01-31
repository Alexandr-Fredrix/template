# Multi-stage build для Java Spring Boot приложения

# ============================================
# Стадия 1: Сборка с Maven
# ============================================
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Копируем pom.xml для кеширования зависимостей
COPY pom.xml .

# Скачиваем зависимости
RUN mvn dependency:go-offline

# Копируем исходники
COPY src ./src

# Собираем приложение (пропускаем тесты для быстрой сборки)
RUN mvn clean package -DskipTests

# ============================================
# Стадия 2: Runtime
# ============================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Создаем пользователя
RUN addgroup -S spring && adduser -S spring -G spring

# Копируем jar файл
COPY --from=builder --chown=spring:spring /app/target/*.jar app.jar

USER spring

# JVM параметры
ENV JAVA_OPTS="-Xmx512m -Xms256m"

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Запуск приложения
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
