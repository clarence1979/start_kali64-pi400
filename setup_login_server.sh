#!/bin/bash

# Exit on error
set -e

echo "[+] Updating packages..."
sudo apt update

echo "[+] Installing Apache2, PHP, MariaDB..."
sudo apt install apache2 php libapache2-mod-php php-mysql mariadb-server unzip -y

echo "[+] Starting and enabling MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "[+] Securing MariaDB (no password prompt)..."
sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "[+] Creating database and user table..."
sudo mysql -uroot -proot <<EOF
CREATE DATABASE IF NOT EXISTS login_db;
USE login_db;
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);
INSERT INTO users (username, password)
VALUES ('admin', '$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")');
EOF

echo "[+] Creating login app in /var/www/html/login..."
sudo mkdir -p /var/www/html/login

cat <<'PHP' | sudo tee /var/www/html/login/db_config.php > /dev/null
<?php
$host = 'localhost';
$db = 'login_db';
$user = 'root';
$pass = 'root';
try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
?>
PHP

cat <<'HTML' | sudo tee /var/www/html/login/login.html > /dev/null
<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
</head>
<body>
    <h2>Login Page</h2>
    <form method="post" action="login.php">
        Username: <input type="text" name="username" required><br><br>
        Password: <input type="password" name="password" required><br><br>
        <input type="submit" value="Login">
    </form>
</body>
</html>
HTML

cat <<'PHP' | sudo tee /var/www/html/login/login.php > /dev/null
<?php
require 'db_config.php';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];
    $stmt = $pdo->prepare("SELECT password FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($user && password_verify($password, $user['password'])) {
        echo "Login successful. Welcome, $username!";
    } else {
        echo "Invalid username or password.";
    }
}
?>
PHP

echo "[+] Restarting Apache..."
sudo systemctl restart apache2

echo "[✓] Setup complete. Visit http://localhost/login/login.html"
