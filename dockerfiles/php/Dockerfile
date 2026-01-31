# Dockerfile для PHP приложения с Nginx и PHP-FPM

FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Устанавливаем системные зависимости
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    zip \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql opcache

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копируем конфигурацию Nginx
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# Копируем конфигурацию Supervisor
COPY docker/supervisor/supervisord.conf /etc/supervisord.conf

# Копируем composer файлы
COPY composer.json composer.lock ./

# Устанавливаем зависимости
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Копируем код приложения
COPY . .

# Генерируем autoloader
RUN composer dump-autoload --optimize --classmap-authoritative

# Настраиваем права
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html/storage

# PHP конфигурация для production
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/health || exit 1

# Запуск через Supervisor (Nginx + PHP-FPM)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
