#!/bin/bash
set -e

# Function to fix permissions
fix_permissions() {
    echo "Fixing permissions..."

    # Ensure storage directories exist
    mkdir -p /var/www/storage/framework/cache/data \
             /var/www/storage/framework/sessions \
             /var/www/storage/framework/views \
             /var/www/storage/framework/testing \
             /var/www/storage/logs \
             /var/www/storage/app/public \
             /var/www/bootstrap/cache

    # Set ownership to www user for writable directories
    chown -R www:www /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

    # If vendor directory exists, ensure it's owned by www
    if [ -d "/var/www/vendor" ]; then
        chown -R www:www /var/www/vendor 2>/dev/null || true
    fi

    # Set directory permissions: 755 (rwxr-xr-x) - owner can write, others can read/execute
    find /var/www/storage -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /var/www/bootstrap/cache -type d -exec chmod 755 {} \; 2>/dev/null || true

    # Set file permissions: 644 (rw-r--r--) - owner can write, others can read
    find /var/www/storage -type f -exec chmod 644 {} \; 2>/dev/null || true
    find /var/www/bootstrap/cache -type f -exec chmod 644 {} \; 2>/dev/null || true

    echo "Permissions fixed."
}

# Fix permissions on startup
fix_permissions

# Execute the main command (php-fpm runs as root, but workers run as www user)
exec "$@"
