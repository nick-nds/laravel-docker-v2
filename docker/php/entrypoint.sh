#!/bin/bash
set -e

# Dev-stage entrypoint: ensures Laravel's writable paths exist on the bind-mount
# and are owned/group-writable by `www`. Kept cheap so container starts stay fast.

ensure_writable_tree() {
    mkdir -p \
        /var/www/storage/framework/cache/data \
        /var/www/storage/framework/sessions \
        /var/www/storage/framework/views \
        /var/www/storage/framework/testing \
        /var/www/storage/logs \
        /var/www/storage/app/public \
        /var/www/bootstrap/cache

    # chown is idempotent and fast when ownership is already correct
    chown -R www:www /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

    # ug+rwX = owner/group get rw, +X adds x only on dirs and already-executable files
    chmod -R ug+rwX /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true
}

ensure_writable_tree

exec "$@"
