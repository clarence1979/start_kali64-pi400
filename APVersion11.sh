#!/bin/bash

# Ethical Cybersecurity Lab - WiFi-Only Version
# For systems with two WiFi interfaces (no Ethernet)

echo "🎓 ETHICAL CYBERSECURITY LAB SETUP (WiFi-Only)"
echo "==============================================="

# Check if root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Configuration
LAB_SSID="CYBERSEC_LAB_DEMO"
LAB_IP="192.168.100.1"
PORTAL_DIR="/var/www/html"
LOG_DIR="/var/log/cybersec_lab"
STUDENT_DATA_DIR="/tmp/lab_students"
mkdir -p "$LOG_DIR" "$STUDENT_DATA_DIR"

# Detect WiFi interfaces
echo "🔍 Detecting WiFi interfaces..."
WIFI_INTERFACES=($(iw dev | grep Interface | awk '{print $2}'))

# Select AP interface
AP_INTERFACE=""
for iface in "${WIFI_INTERFACES[@]}"; do
    if iw phy$(iw dev $iface info | grep wiphy | awk '{print $2}') info | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        AP_INTERFACE="$iface"
        echo "✅ Found AP-capable interface: $AP_INTERFACE"
        break
    fi
done

if [ -z "$AP_INTERFACE" ]; then
    echo "❌ No AP-capable interface found"
    exit 1
fi

# Select second WiFi interface for internet
INTERNET_INTERFACE=""
for iface in "${WIFI_INTERFACES[@]}"; do
    if [ "$iface" != "$AP_INTERFACE" ] && ip link show "$iface" | grep -q "state UP"; then
        INTERNET_INTERFACE="$iface"
        echo "🌐 Using $INTERNET_INTERFACE for internet access"
        break
    fi
done

if [ -z "$INTERNET_INTERFACE" ]; then
    echo "❌ No second WiFi interface with internet access found"
    exit 1
fi

# Stop conflicting services
echo "🛠️ Stopping conflicting services..."
systemctl stop NetworkManager 2>/dev/null
pkill hostapd 2>/dev/null
pkill dnsmasq 2>/dev/null

# Reset AP interface
ip link set "$AP_INTERFACE" down
iw dev "$AP_INTERFACE" set type managed 2>/dev/null || true
ip addr flush dev "$AP_INTERFACE"
ip link set "$AP_INTERFACE" up

# Install required packages
echo "📦 Installing required packages..."
apt update -qq
apt install -y apache2 dnsmasq hostapd php

# Configure hostapd
cat <<EOF > /tmp/hostapd.conf
interface=$AP_INTERFACE
driver=nl80211
ssid=$LAB_SSID
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Assign static IP
ip addr add $LAB_IP/24 dev "$AP_INTERFACE"

# Start hostapd
echo "📡 Starting Access Point on $AP_INTERFACE..."
hostapd /tmp/hostapd.conf > "$LOG_DIR/hostapd.log" 2>&1 &
sleep 5

if ! pgrep -f hostapd > /dev/null; then
    echo "❌ Failed to start hostapd. Check $LOG_DIR/hostapd.log"
    exit 1
fi

# Configure dnsmasq
cat <<EOF > /tmp/dnsmasq.conf
interface=$AP_INTERFACE
dhcp-range=192.168.100.50,192.168.100.150,12h
dhcp-option=3,$LAB_IP
dhcp-option=6,$LAB_IP
address=/#/$LAB_IP
log-queries
log-facility=$LOG_DIR/dnsmasq.log
EOF

dnsmasq -C /tmp/dnsmasq.conf --pid-file=/tmp/dnsmasq.pid > "$LOG_DIR/dnsmasq_start.log" 2>&1 &

# Configure NAT and iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -t nat -F

iptables -t nat -A POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE
iptables -A FORWARD -i "$AP_INTERFACE" -o "$INTERNET_INTERFACE" -j ACCEPT
iptables -A FORWARD -i "$INTERNET_INTERFACE" -o "$AP_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A PREROUTING -i "$AP_INTERFACE" -p tcp --dport 80 -j DNAT --to-destination $LAB_IP
iptables -t nat -A PREROUTING -i "$AP_INTERFACE" -p tcp --dport 443 -j DNAT --to-destination $LAB_IP

# Create basic portal
echo "🧼 Setting up default web portal..."
rm -rf "$PORTAL_DIR"/*
echo '<html><body><h1>Cybersecurity Lab</h1><p>This is a demo WiFi lab. Your traffic is being monitored for educational purposes.</p></body></html>' > "$PORTAL_DIR/index.html"
chown -R www-data:www-data "$PORTAL_DIR"
systemctl restart apache2

echo ""
echo "✅ LAB SETUP COMPLETE"
echo "- SSID: $LAB_SSID"
echo "- AP Interface: $AP_INTERFACE"
echo "- Internet via: $INTERNET_INTERFACE"
echo "- Lab Portal: http://$LAB_IP"
echo "- Logs: $LOG_DIR"
