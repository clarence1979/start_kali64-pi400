#!/bin/bash
set -e

echo "[+] Updating packages..."
sudo apt update

echo "[+] Installing Apache2, PHP, and MariaDB..."
sudo apt install apache2 php libapache2-mod-php php-mysql mariadb-server unzip -y

echo "[+] Stopping any running MariaDB/MySQL processes..."
sudo killall -9 mariadbd mysqld mysqld_safe 2>/dev/null || true

echo "[+] Initializing MariaDB if needed..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql || true

echo "[+] Starting MariaDB in recovery mode to reset root password..."
sudo mysqld_safe --skip-grant-tables & sleep 5

echo "[+] Resetting root password to 'root'..."
mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
EOF

echo "[+] Stopping recovery mode MariaDB..."
sudo killall -9 mariadbd mysqld mysqld_safe || true
sleep 2

echo "[+] Starting MariaDB normally..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "[+] Creating database and user table..."
hashed_pass=$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")
mysql -uroot -proot <<EOF
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

echo "[+] Creating /var/www/html/login..."
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
session_start();
require 'db_config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];
    $stmt = $pdo->prepare("SELECT password FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user && password_verify($password, $user['password'])) {
        header("Location: dashboard.html");
        exit();
    } else {
        echo "Invalid username or password.";
    }
}
?>
PHP

echo "[+] Writing dashboard.html..."
cat <<'HTML' | sudo tee /var/www/html/login/dashboard.html > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>IP and Location Viewer</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin: 20px; }
        #map { height: 400px; width: 80%; margin: auto; margin-top: 20px; }
        .info { margin-top: 10px; }
    </style>
</head>
<body>
    <h1>IP and Location Information</h1>
    <div class="info">
        <p><strong>Local IP:</strong> <span id="local-ip">Detecting...</span></p>
        <p><strong>Public IP:</strong> <span id="public-ip">Detecting...</span></p>
        <p><strong>Location:</strong> <span id="location">Detecting...</span></p>
    </div>
    <div id="map"></div>

    <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
    <script>
        function getLocalIP(callback) {
            let pc = new RTCPeerConnection({iceServers: []});
            pc.createDataChannel('');
            pc.createOffer().then(offer => pc.setLocalDescription(offer));
            pc.onicecandidate = (ice) => {
                if (!ice || !ice.candidate || !ice.candidate.candidate) return;
                const ipRegex = /([0-9]{1,3}(\\.[0-9]{1,3}){3})/;
                const ipMatch = ice.candidate.candidate.match(ipRegex);
                if (ipMatch) {
                    callback(ipMatch[1]);
                }
                pc.close();
            };
        }

        getLocalIP(ip => {
            document.getElementById('local-ip').textContent = ip;
        });

        fetch('https://ipinfo.io/json')
            .then(response => response.json())
            .then(data => {
                const publicIP = data.ip;
                const loc = data.loc.split(',');
                const city = data.city;
                const region = data.region;
                const country = data.country;

                document.getElementById('public-ip').textContent = publicIP;
                document.getElementById('location').textContent = `${city}, ${region}, ${country}`;

                const lat = parseFloat(loc[0]);
                const lon = parseFloat(loc[1]);

                const map = L.map('map').setView([lat, lon], 10);
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: 'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors'
                }).addTo(map);

                L.marker([lat, lon]).addTo(map)
                    .bindPopup(`You are near ${city}, ${country}`)
                    .openPopup();
            })
            .catch(error => {
                console.error('Error fetching public IP/location:', error);
            });
    </script>
</body>
</html>
HTML

echo "[+] Restarting Apache..."
sudo systemctl restart apache2

echo "[✓] Setup complete. Visit: http://localhost/login/login.html"
