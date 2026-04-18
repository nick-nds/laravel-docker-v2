# Laravel Docker Setup

Dev Docker environment for Laravel projects. One multi-stage `Dockerfile`, a small set of services, sensible defaults.

## What's in the box

- **PHP 8.4-FPM** (pin any 8.x via `PHP_VERSION`), Xdebug, Redis, OPcache with JIT
- PHP extensions: `bcmath`, `exif`, `gd`, `intl`, `mbstring`, `opcache`, `pcntl`, `pdo_mysql`, `pdo_pgsql`, `pgsql`, `sockets`, `zip`, `redis`
- **Multi-stage Dockerfile** — `base` → `dev` / `vendor` → `prod` (prod images stay small; no Xdebug, no dev tools)
- **MySQL 8.4** (default) — switch to Postgres without rebuilding the image
- **Redis 8**
- **Nginx 1.27** with HTTP/2, modern ciphers, security headers, optional HTTPS
- **Mailpit** for email capture
- **MinIO** (S3-compatible) — bucket auto-created by an `mc` init sidecar
- **Reverb** (optional profile) for Laravel WebSockets
- **Queue worker** that reuses the built app image (no duplicate build)
- **Helper scripts** so you never run `docker compose exec` directly

## Quick start

### 1. Copy the template into your Laravel project

```bash
# From the root of your Laravel app
cp -r /path/to/laravel-docker-v2/. .
```

### 2. Generate a `.env` + self-signed SSL

```bash
cp .env.example .env
./docker/scripts/generate-ssl.sh laravel.test
```

Edit `.env` — at minimum set `COMPOSE_PROJECT_NAME`, `DOCKER_SERVER_NAME`, `APP_NAME`.

### 3. Build + start the core services

```bash
docker compose up -d --build
```

### 4. Install dependencies and boot the app

```bash
./docker/scripts/composer install
./docker/scripts/artisan key:generate
./docker/scripts/artisan migrate
```

### 5. Map the dev hostname

Add to `/etc/hosts` (macOS/Linux) or `C:\Windows\System32\drivers\etc\hosts`:

```
127.0.0.1  laravel.test
```

### 6. Open it

- HTTPS: `https://laravel.test:40443`
- HTTP:  `http://laravel.test:8000`
- Mailpit: `http://localhost:48025`
- MinIO console: `http://localhost:49001`

## Helper scripts

Always prefer these — they run inside the container as the `www` user so permissions stay correct.

```bash
./docker/scripts/artisan       [args]   # php artisan ...
./docker/scripts/artisan-debug [args]   # php artisan ... with Xdebug
./docker/scripts/composer      [args]   # composer ...
./docker/scripts/test          [args]   # php artisan test ...
./docker/scripts/shell                  # bash inside the app container
./docker/scripts/generate-ssl.sh [cn]   # self-signed dev cert
```

## Common commands

```bash
# Laravel
./docker/scripts/artisan migrate:fresh --seed
./docker/scripts/artisan make:model Product -m
./docker/scripts/test --filter=SomeTest

# Docker
docker compose up -d
docker compose down
docker compose logs -f app
docker compose restart app

# DB (from host)
mysql -h 127.0.0.1 -P 43306 -u app -papp laravel
```

## Optional services (compose profiles)

```bash
# WebSockets via Reverb
docker compose --profile reverb up -d

# tmpfs-backed test DB (parallel test runs, fast teardown)
docker compose --profile testing up -d mysql-test

# One-shot composer (e.g. bootstrap a project before `app` exists)
docker compose --profile tools run --rm composer create-project laravel/laravel .
```

## Xdebug

- **Mode**: `debug,develop,coverage`, trigger-only (no per-request overhead).
- **Port**: `9003` on the host.
- **Path mapping**: local project root → `/var/www`.

Browser: use the Xdebug Helper extension (sets the `XDEBUG_SESSION` cookie).

CLI: `./docker/scripts/artisan-debug migrate` (sets `XDEBUG_SESSION=1`).

Disable entirely for a session:

```bash
XDEBUG_MODE=off docker compose up -d app
```

VS Code `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": { "/var/www": "${workspaceFolder}" }
  }]
}
```

## Services & ports

| Service | Host port | Env var |
|---|---|---|
| Nginx HTTP | 8000 | `DOCKER_NGINX_HTTP_PORT` |
| Nginx HTTPS | 40443 | `DOCKER_NGINX_HTTPS_PORT` |
| MySQL | 43306 | `DOCKER_MYSQL_LOCAL_PORT` |
| MySQL test (`--profile testing`) | 43307 | `DOCKER_MYSQL_TEST_PORT` |
| Redis | 46379 | `DOCKER_REDIS_LOCAL_PORT` |
| Mailpit SMTP | 41025 | `DOCKER_MAILPIT_SMTP_PORT` |
| Mailpit web | 48025 | `DOCKER_MAILPIT_WEB_PORT` |
| MinIO API | 49000 | `DOCKER_MINIO_API_PORT` |
| MinIO console | 49001 | `DOCKER_MINIO_CONSOLE_PORT` |
| Reverb (`--profile reverb`) | 48080 | `DOCKER_REVERB_LOCAL_PORT` |

**Databases:** `laravel` (main), `laravel_testing` (for tests). **Credentials:** `app`/`app` (root: `root`/`root`).

**MinIO:** default bucket `laravel-local`, credentials `local`/`localsecret`. The `minio-init` sidecar creates the bucket on every start (idempotent).

## Customizing

### Pin a different PHP minor

```env
PHP_VERSION=8.3
```

Then: `docker compose build app`.

### Switch to PostgreSQL

The base image already ships `pdo_pgsql` — just swap the DB service. Create `compose.override.yml`:

```yaml
services:
  postgres:
    image: postgres:17-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-laravel}-postgres
    restart: unless-stopped
    ports: ["${DOCKER_MYSQL_LOCAL_PORT:-43306}:5432"]
    environment:
      POSTGRES_DB: ${DB_DATABASE:-laravel}
      POSTGRES_USER: ${DB_USERNAME:-app}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-app}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks: [laravel]
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "${DB_USERNAME:-app}"]
      interval: 10s

  app:
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
```

Update `.env`:

```env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
```

Then: `docker compose down && docker compose up -d --build`.

### Add a PHP extension

```dockerfile
# Dockerfile, in the base stage
docker-php-ext-install -j"$(nproc)" ... your_extension
```

Rebuild: `docker compose build app`.

### Multi-tenancy

Not a template default. If you need additional databases:

```sql
-- docker/mysql/init-databases.sql
CREATE DATABASE IF NOT EXISTS `tenant_1`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON `tenant_1`.* TO 'app'@'%';
```

Reset the MySQL volume so the init script runs again:

```bash
docker compose down -v
docker compose up -d
```

## Troubleshooting

**Permission denied:**

```bash
docker compose restart app   # entrypoint re-applies permissions
```

**Composer out of memory:** bump `memory_limit` in `docker/php/local.ini`.

**Xdebug not connecting:**
- IDE listening on port 9003?
- Trigger set? (`XDEBUG_SESSION` cookie or `XDEBUG_SESSION=1` env)
- Path mapping = `/var/www` → local project root?

**Starting over:**

```bash
docker compose down -v
docker compose up -d --build
./docker/scripts/composer install
./docker/scripts/artisan migrate
```

## Architecture notes

- **Multi-stage Dockerfile** — shared `base` (PHP + extensions + composer), `dev` (adds Xdebug + bind-mount entrypoint), `vendor` (deterministic `composer install` with a BuildKit cache mount), `prod` (assembled from `vendor`, no dev tools, runs as `www`).
- **Dev uses bind-mounts**, not `COPY` — so the dev image doesn't carry a stale snapshot of source.
- **Permissions**: the `dev` entrypoint ensures `storage/` + `bootstrap/cache/` are owned and writable by `www` on every start (cheap and idempotent).
- **Queue and Reverb reuse** the already-built `app` image (`image: ${COMPOSE_PROJECT_NAME}-app:dev`), skipping a second build.
- **Healthchecks** on DB/Redis/MinIO so `depends_on: condition: service_healthy` is meaningful.
