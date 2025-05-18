#!/bin/bash
set -e

echo "[+] Updating packages..."
sudo apt update

echo "[+] Installing Apache2, PHP, MariaDB, and required PHP extensions..."
sudo apt install apache2 php libapache2-mod-php php-mysql mariadb-server unzip -y

echo "[+] Purging old MariaDB config and data (if any)..."
sudo systemctl stop mariadb || true
sudo killall -9 mariadbd mysqld mysqld_safe 2>/dev/null || true
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/run/mysqld
sudo mkdir -p /etc/mysql/conf.d /etc/mysql/mariadb.conf.d

echo "[+] Reinstalling MariaDB fresh..."
sudo apt install --reinstall mariadb-server -y

echo "[+] Initializing MariaDB..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

echo "[+] Starting MariaDB in password reset mode..."
sudo mysqld_safe --skip-grant-tables & sleep 5

echo "[+] Resetting root password..."
mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
EOF

echo "[+] Restarting MariaDB in normal mode..."
sudo killall -9 mariadbd mysqld mysqld_safe
sleep 2
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "[+] Creating login_db and users table..."
HASHED_PASS=$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")
mysql -u root -proot <<EOF
CREATE DATABASE IF NOT EXISTS login_db;
USE login_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);
DELETE FROM users WHERE username='admin';
INSERT INTO users (username, password) VALUES ('admin', '$HASHED_PASS');
EOF

echo "[+] Setting up web app in /var/www/html/login..."
sudo mkdir -p /var/www/html/login
sudo chown -R $USER:www-data /var/www/html/login
sudo chmod -R 755
