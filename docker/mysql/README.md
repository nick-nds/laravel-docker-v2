# MySQL Configuration

This directory contains MySQL configuration files for the Docker setup.

## Files

### `my.cnf`
MySQL server configuration with optimized settings for Laravel development.

### `init-databases.sql`
Initialization script that creates default databases on first container startup.

**Created Databases:**
- `landlord` - Central tenant management database
- `tenant1` - First tenant database
- `tenant2` - Second tenant database

**Note:** This script only runs on **first initialization** when the MySQL data volume is empty.

## How Database Initialization Works

The MySQL Docker image automatically executes `.sql` files in `/docker-entrypoint-initdb.d/` directory when:
1. Container starts for the first time
2. MySQL data volume is empty (no existing data)

If databases already exist, the script is skipped.

## Resetting Databases

To re-run the initialization script:

```bash
# Stop containers
docker compose down

# Remove MySQL volume (⚠️ WARNING: Deletes all data!)
docker volume rm crm_mysql_data

# Start containers (init script will run)
docker compose up -d
```

## Adding More Databases

Edit `init-databases.sql` and add:

```sql
CREATE DATABASE IF NOT EXISTS `your_database`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `your_database`.* TO 'app'@'%';
```

Then reset the MySQL volume (see above).

## Connecting to Databases

```bash
# Connect to landlord database
docker compose exec mysql mysql -uapp -papp landlord

# Connect to tenant database
docker compose exec mysql mysql -uapp -papp tenant1

# List all databases
docker compose exec mysql mysql -uroot -proot -e "SHOW DATABASES;"
```

## Credentials

Default credentials (configured in `.env`):
- **Root Password**: `root`
- **User**: `app`
- **Password**: `app`
