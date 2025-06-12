#!/bin/bash

# Ethical Cybersecurity Lab - Transparent WiFi Security Demonstration
# This creates an educational environment with full disclosure and consent

echo "🎓 ETHICAL CYBERSECURITY LAB SETUP"
echo "=================================="
echo "Creating a transparent educational WiFi security demonstration"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root (sudo)"
   exit 1
fi

# STEP 0: Install dependencies before network goes down
echo "🌐 Installing required packages before disrupting WiFi..."
apt update -qq
apt install -y apache2 dnsmasq hostapd php tshark tcpdump
if [[ $? -ne 0 ]]; then
   echo "❌ Failed to install required packages. Check your internet connection."
   exit 1
fi
echo "✅ Required packages installed"

# Ask for SSID name
read -p "📶 Enter the SSID name for the lab WiFi (default: CYBERSEC_LAB_DEMO): " LAB_SSID
LAB_SSID=${LAB_SSID:-CYBERSEC_LAB_DEMO}

# Configuration
WIFI_INTERFACE=""
PORTAL_DIR="/var/www/html"
LOG_DIR="/var/log/cybersec_lab"
STUDENT_DATA_DIR="/tmp/lab_students"

# Create necessary directories
mkdir -p "$LOG_DIR" "$STUDENT_DATA_DIR"

echo "🔍 STEP 1: Network Interface Detection"
echo "====================================="

# Find a WiFi interface that supports AP mode
for iface in $(iw dev | grep Interface | awk '{print $2}'); do
    if iw phy$(iw dev $iface info | grep wiphy | awk '{print $2}') info | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        WIFI_INTERFACE="$iface"
        echo "✅ Found AP-capable interface: $WIFI_INTERFACE"
        break
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "❌ No AP-capable WiFi interface found"
    exit 1
fi

echo ""
echo "🛰️ STEP 2: Scan Nearby Networks for Educational Context"
echo "========================================================"
timeout 10 iwlist "$WIFI_INTERFACE" scan | grep -E "ESSID|Encryption|Signal" | head -20
echo ""
echo "💡 This illustrates how attackers can identify and mimic legitimate networks."
echo ""

echo "🛠️ STEP 3: Reset and Configure WiFi Interface"
echo "============================================="
systemctl stop NetworkManager 2>/dev/null
pkill create_ap hostapd dnsmasq tcpdump 2>/dev/null

ip link set "$WIFI_INTERFACE" down
iw dev "$WIFI_INTERFACE" set type managed || true
ip addr flush dev "$WIFI_INTERFACE"
ip link set "$WIFI_INTERFACE" up

echo "✅ Interface prepared"

echo "📶 STEP 4: Launching Access Point"
echo "=================================="
cat <<EOF > /tmp/lab_hostapd.conf
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$LAB_SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
ieee80211n=1
EOF

ip addr add 192.168.100.1/24 dev "$WIFI_INTERFACE"
LAB_IP="192.168.100.1"

hostapd /tmp/lab_hostapd.conf > "$LOG_DIR/hostapd.log" 2>&1 &
sleep 5

if ! pgrep -f hostapd > /dev/null; then
    echo "❌ Failed to start access point"
    cat "$LOG_DIR/hostapd.log"
    exit 1
fi
echo "✅ Access point '$LAB_SSID' started"

echo "🧠 STEP 5: Creating Captive Portal"
echo "=================================="
# Basic HTML Portal (index.html)
cat <<EOF > "$PORTAL_DIR/index.html"
<!DOCTYPE html>
<html>
<head><title>Cybersecurity Lab</title></head>
<body>
<h1>🎓 Cybersecurity Lab - WiFi Security Demo</h1>
<p>This is a controlled and ethical demonstration of WiFi monitoring techniques.</p>
<form action="/register.php" method="POST">
    Name: <input type="text" name="name" required><br>
    Email: <input type="email" name="email" required><br>
    <button type="submit">Participate</button>
</form>
</body>
</html>
EOF

# Basic registration backend
cat <<'EOF' > "$PORTAL_DIR/register.php"
<?php
$ip = $_SERVER['REMOTE_ADDR'];
$name = $_POST['name'] ?? 'unknown';
$email = $_POST['email'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');
$log = "[$timestamp] IP: $ip | Name: $name | Email: $email\n";
file_put_contents('/var/log/cybersec_lab/registrations.log', $log, FILE_APPEND | LOCK_EX);
header("Location: /thankyou.html");
exit;
?>
EOF

# Simple thank-you page
echo "<h1>✅ You are now part of the lab!</h1>" > "$PORTAL_DIR/thankyou.html"

# Permissions
chown -R www-data:www-data "$PORTAL_DIR"
chmod -R 755 "$PORTAL_DIR"

systemctl restart apache2

echo "📡 STEP 6: Configuring DHCP and DNS"
echo "==================================="
cat <<EOF > /tmp/lab_dnsmasq.conf
interface=$WIFI_INTERFACE
dhcp-range=192.168.100.50,192.168.100.150,12h
dhcp-option=3,$LAB_IP
dhcp-option=6,$LAB_IP
address=/#/$LAB_IP
log-queries
log-facility=$LOG_DIR/dns_queries.log
no-resolv
server=8.8.8.8
server=1.1.1.1
EOF

dnsmasq -C /tmp/lab_dnsmasq.conf --pid-file=/tmp/dnsmasq.pid > "$LOG_DIR/dnsmasq.log" 2>&1 &

echo "🛡️ STEP 7: Configuring Firewall & Captive Redirect"
echo "=================================================="
iptables -F
iptables -t nat -F
iptables -P FORWARD DROP

iptables -A FORWARD -i "$WIFI_INTERFACE" -p tcp --dport 80 -d "$LAB_IP" -j ACCEPT
iptables -A FORWARD -i "$WIFI_INTERFACE" -p udp --dport 53 -j ACCEPT
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 80 -j DNAT --to-destination "$LAB_IP:80"
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 443 -j DNAT --to-destination "$LAB_IP:80"

# Enable NAT for outbound traffic (if allowed)
PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -n "$PRIMARY_IFACE" ]; then
    iptables -t nat -A POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE
fi

echo 1 > /proc/sys/net/ipv4/ip_forward

echo "✅ Firewall and NAT configured"

echo "🚦 STEP 8: Captive Portal Detection Support"
echo "==========================================="
ln -sf index.html "$PORTAL_DIR/generate_204"
ln -sf index.html "$PORTAL_DIR/hotspot-detect.html"
ln -sf index.html "$PORTAL_DIR/ncsi.txt"
ln -sf index.html "$PORTAL_DIR/connecttest.txt"

echo "🎯 LAB READY"
echo "============"
echo "✔ Network SSID: $LAB_SSID"
echo "✔ Access Point IP: $LAB_IP"
echo "✔ Captive portal: http://$LAB_IP"
echo "✔ Logs: $LOG_DIR"
echo ""
echo "To stop the lab, run:"
echo "sudo pkill hostapd dnsmasq"
echo "sudo iptables -F && sudo iptables -t nat -F"
echo "sudo systemctl start NetworkManager"
