FROM php:8.3-fpm

# Set arguments for user and group ID
ARG UID=1000
ARG GID=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    supervisor \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache \
    sockets

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Xdebug (for development)
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN groupadd -g ${GID} www || true \
    && useradd -u ${UID} -ms /bin/bash -g www www || true

# Copy PHP-FPM pool configuration
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy entrypoint script
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /var/www

# Copy application files with restrictive permissions
COPY --chown=www:www . /var/www

# Set secure base permissions: 755 for directories, 644 for files
RUN find /var/www -type d -exec chmod 755 {} \; \
    && find /var/www -type f -exec chmod 644 {} \;

# Create necessary directories with proper ownership
RUN mkdir -p /var/www/storage/framework/cache/data \
    /var/www/storage/framework/sessions \
    /var/www/storage/framework/views \
    /var/www/storage/framework/testing \
    /var/www/storage/logs \
    /var/www/storage/app/public \
    /var/www/bootstrap/cache \
    && chown -R www:www /var/www/storage /var/www/bootstrap/cache

# Set permissions on storage and cache directories
# Directories: 755 (rwxr-xr-x) - owner can write, group/others read+execute
# Files will be set at runtime by entrypoint
RUN find /var/www/storage -type d -exec chmod 755 {} \; \
    && find /var/www/bootstrap/cache -type d -exec chmod 755 {} \;

# Expose port 9000
EXPOSE 9000

# Use entrypoint script to fix permissions at runtime
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start php-fpm
CMD ["php-fpm"]
