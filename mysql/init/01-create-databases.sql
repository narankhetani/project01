-- mysql/init/01-create-databases.sql

-- Create databases for each WordPress site
CREATE DATABASE IF NOT EXISTS wordpress_main CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress_reviews CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress_fintech CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create users for each site
CREATE USER IF NOT EXISTS 'wp_main_user'@'%' IDENTIFIED BY 'wp_main_password_2025';
CREATE USER IF NOT EXISTS 'wp_reviews_user'@'%' IDENTIFIED BY 'wp_reviews_password_2025';
CREATE USER IF NOT EXISTS 'wp_fintech_user'@'%' IDENTIFIED BY 'wp_fintech_password_2025';

-- Grant privileges
GRANT ALL PRIVILEGES ON wordpress_main.* TO 'wp_main_user'@'%';
GRANT ALL PRIVILEGES ON wordpress_reviews.* TO 'wp_reviews_user'@'%';
GRANT ALL PRIVILEGES ON wordpress_fintech.* TO 'wp_fintech_user'@'%';

-- Flush privileges
FLUSH PRIVILEGES;