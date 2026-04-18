# MySQL config

MySQL 8.4 configuration used by the `mysql` service in `docker-compose.yml`.

## Files

- **`my.cnf`** — server tunings for Laravel dev (utf8mb4 everywhere, modest InnoDB buffer, slow-query logging on).
- **`init-databases.sql`** — runs once on first container startup. Creates the `laravel_testing` database and grants the `app` user. The main `laravel` database is created automatically by the `MYSQL_DATABASE` env var, so it isn't in this file.

The init script only executes when the `mysql_data` volume is empty. To re-run it:

```bash
docker compose down
docker volume rm ${COMPOSE_PROJECT_NAME:-laravel}_mysql_data
docker compose up -d
```

## Customizing

**Add another database (e.g. a second tenant):**

```sql
CREATE DATABASE IF NOT EXISTS `tenant_1`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `tenant_1`.* TO 'app'@'%';
```

Then reset the volume (see above).

**Connect from the host:**

```bash
mysql -h 127.0.0.1 -P 43306 -u app -papp laravel
```

**Connect from inside the compose network:**

```bash
docker compose exec mysql mysql -u app -papp laravel
```
