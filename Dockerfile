# syntax=docker/dockerfile:1.7

ARG PHP_VERSION=8.4

# ============================================================================
# base — shared by dev, vendor, and prod stages
# ============================================================================
FROM php:${PHP_VERSION}-fpm-bookworm AS base

ARG UID=1000
ARG GID=1000

ENV COMPOSER_ALLOW_SUPERUSER=1

# System dependencies (common to every stage)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      libcurl4-openssl-dev \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libonig-dev \
      libpng-dev \
      libpq-dev \
      libssl-dev \
      libwebp-dev \
      libxml2-dev \
      libxpm-dev \
      libzip-dev \
      supervisor \
      unzip \
      zip \
 && rm -rf /var/lib/apt/lists/*

# PHP extensions (bundle both pdo_mysql and pdo_pgsql so consumers can switch
# DBs via env without rebuilding the image)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" \
      bcmath \
      exif \
      gd \
      intl \
      mbstring \
      opcache \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      sockets \
      zip

# Redis extension (pinned for reproducibility)
RUN pecl install redis-6.1.0 \
 && docker-php-ext-enable redis

# Composer (pinned to major)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Non-root user (runtime processes should never run as root)
RUN groupadd -g ${GID} www 2>/dev/null || true \
 && useradd -u ${UID} -ms /bin/bash -g www www 2>/dev/null || true

# Shared PHP-FPM + OPcache config
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/10-opcache.ini

WORKDIR /var/www

EXPOSE 9000
CMD ["php-fpm"]

# ============================================================================
# dev — adds Xdebug + permission-fixing entrypoint for bind-mounted source
# ============================================================================
FROM base AS dev

RUN pecl install xdebug-3.4.1 \
 && docker-php-ext-enable xdebug

COPY docker/php/local.ini /usr/local/etc/php/conf.d/20-local.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

# ============================================================================
# vendor — isolated composer install for a deterministic prod build
# ============================================================================
FROM base AS vendor

# Install dependencies first (cache-friendly: only re-runs when lock changes)
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install \
      --no-dev \
      --no-scripts \
      --no-interaction \
      --prefer-dist \
      --no-autoloader

# Bring in app sources, then regenerate an optimized autoloader
COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative --no-scripts

# ============================================================================
# prod — small runtime image, no Xdebug, no dev tooling, runs as www user
# ============================================================================
FROM base AS prod

COPY docker/php/prod.ini /usr/local/etc/php/conf.d/99-prod.ini

COPY --from=vendor --chown=www:www /var/www /var/www

RUN mkdir -p /var/www/storage/framework/cache/data \
             /var/www/storage/framework/sessions \
             /var/www/storage/framework/views \
             /var/www/storage/logs \
             /var/www/bootstrap/cache \
 && chown -R www:www /var/www/storage /var/www/bootstrap/cache \
 && chmod -R ug+rwX /var/www/storage /var/www/bootstrap/cache

USER www

CMD ["php-fpm"]
