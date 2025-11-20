-- MySQL Initialization Script
-- Creates default databases for Laravel multi-tenant application
-- This script runs automatically on first container startup

-- Create landlord database (central tenant management)
CREATE DATABASE IF NOT EXISTS `landlord`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create tenant databases
CREATE DATABASE IF NOT EXISTS `tenant1`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS `tenant2`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Grant privileges to app user for landlord database
GRANT ALL PRIVILEGES ON `landlord`.* TO 'app'@'%';

-- Grant privileges to app user for tenant databases
GRANT ALL PRIVILEGES ON `tenant1`.* TO 'app'@'%';
GRANT ALL PRIVILEGES ON `tenant2`.* TO 'app'@'%';

-- Flush privileges to ensure they take effect
FLUSH PRIVILEGES;

-- Display created databases
SELECT CONCAT('✓ Created database: ', SCHEMA_NAME) as 'Status'
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME IN ('landlord', 'tenant1', 'tenant2')
ORDER BY SCHEMA_NAME;
