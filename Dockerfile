# ===============================================
# LaravelProjectContainer - Custom FrankenPHP Image
# ===============================================
# Multi-stage build for optimal production image
# Created by Denis Djodian Ardika - Artelia.Dev
# ===============================================

# ===============================================
# Stage 1: Composer Dependencies
# ===============================================
FROM composer:latest as composer

# ===============================================
# Stage 2: FrankenPHP Base Image
# ===============================================
FROM dunglas/frankenphp:latest as frankenphp

# Set working directory
WORKDIR /var/www/html

# ===============================================
# System Dependencies & Tools
# ===============================================
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    unzip \
    git \
    vim \
    nano \
    htop \
    supervisor \
    cron \
    && rm -rf /var/lib/apt/lists/*

# ===============================================
# PHP Extensions Installation
# ===============================================
RUN install-php-extensions \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    pgsql \
    redis \
    memcached \
    bcmath \
    ctype \
    fileinfo \
    json \
    mbstring \
    openssl \
    tokenizer \
    xml \
    zip \
    gd \
    intl \
    exif \
    imagick \
    xdebug \
    opcache

# ===============================================
# PHP Configuration
# ===============================================
# Xdebug Configuration
RUN echo "xdebug.mode=debug,coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Custom PHP Configuration
RUN echo "memory_limit=512M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize=100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_input_vars=3000" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "date.timezone=Asia/Makassar" >> /usr/local/etc/php/conf.d/custom.ini

# OPcache Configuration
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini

# ===============================================
# Composer Installation
# ===============================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ===============================================
# Node.js & Frontend Tools
# ===============================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Global Node.js packages
RUN npm install -g \
    @vue/cli \
    @angular/cli \
    create-react-app \
    vite \
    eslint \
    prettier

# ===============================================
# Laravel Global Installation
# ===============================================
RUN composer global require laravel/installer

# ===============================================
# Directory Structure & Permissions
# ===============================================
RUN mkdir -p /var/www/html/Projects \
    && mkdir -p /var/www/html/Terminal \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /var/log/cron \
    && mkdir -p /var/run

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# ===============================================
# Copy Configuration Files
# ===============================================
# Supervisor configuration
COPY ./Supervisor/supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# Terminal scripts
COPY ./Terminal/*.sh /var/www/html/Terminal/
RUN chmod +x /var/www/html/Terminal/*.sh

# Crontab for Laravel scheduler
COPY ./Config/crontab /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron \
    && crontab /etc/cron.d/laravel-cron

# ===============================================
# Health Check Endpoint
# ===============================================
RUN echo '<?php echo "OK"; ?>' > /var/www/html/health.php

# ===============================================
# Expose Ports
# ===============================================
EXPOSE 8000 8001 8002 8003 8004 8005 8006 8007 8008 8009 80 443

# ===============================================
# Startup Script
# ===============================================
COPY ./Scripts/startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# ===============================================
# Environment Variables
# ===============================================
ENV PATH="/var/www/html/Terminal:${PATH}"
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME="/tmp/composer"

# ===============================================
# Entry Point
# ===============================================
ENTRYPOINT ["/usr/local/bin/startup.sh"]

# Default command
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]