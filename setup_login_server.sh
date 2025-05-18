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

echo "[+] Creating /var/www/html/login directory..."

if [ ! -d /var/www/html ]; then
    echo "[-] Apache web root not found. Is Apache installed correctly?"
    exit 1
fi

sudo mkdir -p /var/www/html/login
sudo chown -R $USER:www-data /var/www/html/login
sudo chmod -R 755 /var/www/html/login

echo "[+] Writing db_config.php..."
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

echo "[+] Writing login.html..."
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

echo "[+] Writing login.php..."
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

echo "[✓] Setup complete. Visit http://localhost/login/login.html in your browser."
