# Laravel Docker Setup

Production-ready Docker development environment for Laravel projects.

## Features

- **PHP 8.3-FPM** with Xdebug, Redis, and all Laravel extensions
- **MySQL 8.4** with separate test database
- **Nginx** with SSL support
- **Redis 7** for caching and queues
- **Queue Worker** for background jobs
- **Mailpit** for email testing
- **Reverb** (optional) for WebSockets
- **LocalStack** (optional) for S3 emulation
- **Helper Scripts** to prevent permission issues
- **Auto-permission fixing** on container startup

## Quick Start

### 1. Clone to your Laravel project

```bash
# Copy all files to your Laravel project root
cp -r docker-template/* /path/to/your/laravel-project/
cd /path/to/your/laravel-project
```

### 2. Configure environment

```bash
# Copy and customize .env
cp .env.example .env

# Update these in .env:
COMPOSE_PROJECT_NAME=myapp       # Unique project name
DOCKER_SERVER_NAME=myapp.test    # Your domain
APP_NAME="My Application"        # App name
```

### 3. Generate SSL certificates

```bash
mkdir -p docker/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/nginx/ssl/key.pem \
  -out docker/nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

### 4. Start Docker

```bash
# Core services only
docker compose up -d --build

# With optional services
docker compose --profile reverb --profile localstack up -d --build
```

### 5. Setup Laravel

```bash
# Make scripts executable
./docker/scripts/setup-helpers.sh

# Install dependencies
./docker/scripts/composer install

# Setup application
./docker/scripts/artisan key:generate
./docker/scripts/artisan migrate
./docker/scripts/artisan db:seed  # Optional
```

### 6. Add to hosts file

```bash
# /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 myapp.test api.myapp.test
```

### 7. Access

- **HTTPS**: https://myapp.test:40443
- **HTTP**: http://myapp.test:8000
- **Mailpit**: http://localhost:48025

## Helper Scripts

**Always use these to avoid permission issues:**

```bash
./docker/scripts/artisan [command]        # Artisan commands
./docker/scripts/artisan-debug [cmd]      # Artisan with Xdebug
./docker/scripts/composer [command]   # Composer
./docker/scripts/test [options]       # Tests
./docker/scripts/shell                # Container shell
```

## Common Commands

```bash
# Laravel
./docker/scripts/artisan migrate
./docker/scripts/artisan make:model Product
./docker/scripts/artisan cache:clear
./docker/scripts/test

# Database
docker compose exec mysql mysql -uapp -papp laravel

# Docker
docker compose up -d              # Start
docker compose down              # Stop
docker compose logs -f app       # Logs
docker compose restart app       # Restart
```

## Optional Services

```bash
# WebSockets (Reverb)
docker compose --profile reverb up -d

# S3 Emulation (LocalStack)
docker compose --profile localstack up -d

# Both
docker compose --profile reverb --profile localstack up -d
```

## Xdebug

**Web:**
1. Install [Xdebug Helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
2. Configure IDE: Port **9003**, Path mapping → `/var/www`
3. Enable extension and make request

**CLI:**
```bash
./docker/scripts/artisan-debug migrate
```

**VS Code** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
      "/var/www": "${workspaceFolder}"
    }
  }]
}
```

## Services & Ports

| Service | Port | Variable |
|---------|------|----------|
| Nginx HTTPS | 40443 | DOCKER_NGINX_LOCAL_PORT |
| Nginx HTTP | 8000 | - |
| MySQL | 43306 | DOCKER_MYSQL_LOCAL_PORT |
| MySQL Test | 43307 | DOCKER_MYSQL_TEST_LOCAL_PORT |
| Redis | 46379 | DOCKER_REDIS_LOCAL_PORT |
| Mailpit Web | 48025 | DOCKER_MAILPIT_WEB_LOCAL_PORT |
| Mailpit SMTP | 41025 | DOCKER_MAILPIT_SMTP_LOCAL_PORT |
| Reverb | 48080 | DOCKER_REVERB_LOCAL_PORT |
| LocalStack | 44566 | DOCKER_LOCALSTACK_LOCAL_PORT |

**Databases:** `laravel` (main), `testing` (for tests)
**Credentials:** root/root, app/app

## Troubleshooting

**Permission Denied:**
```bash
docker compose restart app
```

**Database Issues:**
```bash
docker compose ps mysql
docker compose logs mysql
```

**Xdebug Not Working:**
- IDE listening on port 9003?
- XDEBUG_SESSION cookie set?
- Path mapping: Local → `/var/www`?

**Start Fresh:**
```bash
docker compose down -v
docker compose up -d --build
./docker/scripts/composer install
./docker/scripts/artisan migrate
```

## Customization

**Change Database:**
1. Update `DB_DATABASE` in `.env`
2. Edit `docker/mysql/init-databases.sql`
3. Reset: `docker compose down -v && docker compose up -d`

**Change PHP Version:**
```dockerfile
# Dockerfile line 1
FROM php:8.2-fpm  # Change from 8.3
```
Then: `docker compose up -d --build`

**Add PHP Extension:**
```dockerfile
# Dockerfile - add to docker-php-ext-install line
&& docker-php-ext-install ... newextension
```
Then: `docker compose up -d --build`

**Change Ports:**
Update `.env` variables and `docker compose down && docker compose up -d`

## Multi-Tenancy

Edit `docker/mysql/init-databases.sql`:
```sql
CREATE DATABASE IF NOT EXISTS `tenant1` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON `tenant1`.* TO 'app'@'%';
```
Then: `docker compose down -v && docker compose up -d`

## Production

This is for **development only**. For production:
- Remove Xdebug
- Use production MySQL config
- Use real SSL certificates
- Use managed services
- Enable OPcache
- Implement monitoring

## Architecture

**Permissions:**
- PHP-FPM master: root (port binding)
- PHP-FPM workers: www (UID 1000)
- Files: 755/644, owned by www:www

**Security:**
- Entrypoint fixes permissions on startup
- Helper scripts enforce www user
- Never use 777 permissions
