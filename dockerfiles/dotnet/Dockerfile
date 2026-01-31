# Multi-stage build для .NET приложения

# ============================================
# Стадия 1: Сборка
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

WORKDIR /src

# Копируем .csproj и восстанавливаем зависимости
COPY *.sln .
COPY MyApp/*.csproj ./MyApp/
RUN dotnet restore

# Копируем остальной код и собираем
COPY MyApp/. ./MyApp/
WORKDIR /src/MyApp
RUN dotnet publish -c Release -o /app/publish

# ============================================
# Стадия 2: Runtime
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Создаем пользователя
RUN useradd -m -u 1000 dotnetuser

# Копируем опубликованное приложение
COPY --from=builder --chown=dotnetuser:dotnetuser /app/publish .

USER dotnetuser

ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "MyApp.dll"]
