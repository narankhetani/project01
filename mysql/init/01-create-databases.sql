-- mysql/init/01-create-databases.sql

-- Create databases for each WordPress site
CREATE DATABASE IF NOT EXISTS wordpress_main CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress_reviews CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress_fintech CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Note: Users will be created by environment variables in docker-compose.yml
-- The MYSQL_USER and MYSQL_PASSWORD environment variables automatically create the first user
-- Additional users for reviews and fintech sites will be created by WordPress on first setup

-- Grant privileges for the main user (created automatically)
-- Additional grants will be handled by WordPress setup