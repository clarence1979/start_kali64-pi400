#!/bin/bash

set -e

echo "[+] Updating packages..."
sudo apt update

echo "[+] Installing Apache2, PHP, MariaDB..."
sudo apt install apache2 php libapache2-mod-php php-mysql mariadb-server unzip -y

echo "[+] Starting and enabling MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "[+] Securing MariaDB with root password..."
sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "[+] Creating login_db database and users table..."
hashed_pass=$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")
sudo mysql -uroot -proot <<EOF
CREATE DATABASE IF NOT EXISTS login_db;
USE login_db;
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);
DELETE FROM users WHERE username='admin';
INSERT INTO users (username, password) VALUES ('admin', '$hashed_pass');
EOF
