-- Runs once on first MySQL container startup (when the mysql_data volume is empty).
-- The main DB named by ${DB_DATABASE} is auto-created from the MYSQL_DATABASE env,
-- so this script only creates the extra test database and grants the app user.

CREATE DATABASE IF NOT EXISTS `laravel_testing`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `laravel_testing`.* TO 'app'@'%';

FLUSH PRIVILEGES;
