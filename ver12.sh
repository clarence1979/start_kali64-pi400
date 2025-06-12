#!/bin/bash

# Ethical Cybersecurity Lab - Transparent WiFi Security Demonstration
# This creates an educational environment with full disclosure and consent

echo "\U1F393 ETHICAL CYBERSECURITY LAB SETUP"
echo "=================================="
echo "Creating a transparent educational WiFi security demonstration"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "\u274C Please run as root (sudo)"
   exit 1
fi

# Ensure all required packages are installed BEFORE disrupting network
echo "\U1F310 Preparing lab: Installing required packages before WiFi reconfiguration..."
apt update -qq
apt install -y apache2 dnsmasq hostapd php tshark tcpdump
if [[ $? -ne 0 ]]; then
   echo "\u274C Failed to install required packages. Check your internet connection."
   exit 1
fi
echo "\u2705 Required packages installed"

# Configuration
WIFI_INTERFACE=""
LAB_SSID="CYBERSEC_LAB_DEMO"  # Clearly identifies as educational
PORTAL_DIR="/var/www/html"
LOG_DIR="/var/log/cybersec_lab"
STUDENT_DATA_DIR="/tmp/lab_students"

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$STUDENT_DATA_DIR"

echo "\U1F50D STEP 1: Network Interface Detection"
echo "====================================="

# Auto-detect WiFi interface
echo "Scanning for WiFi interfaces..."
for iface in $(iw dev | grep Interface | awk '{print $2}'); do
    if iw phy$(iw dev $iface info | grep wiphy | awk '{print $2}') info | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        WIFI_INTERFACE="$iface"
        echo "\u2705 Found AP-capable interface: $WIFI_INTERFACE"
        break
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "\u274C No AP-capable WiFi interface found"
    echo "Please ensure you have a WiFi adapter that supports AP mode"
    exit 1
fi

# Show nearby networks for educational context
echo ""
echo "\U1F4F0 STEP 2: Educational Context - Nearby Networks"
echo "=============================================="
echo "Scanning nearby WiFi networks to demonstrate security concepts..."
timeout 10 iwlist "$WIFI_INTERFACE" scan | grep -E "ESSID|Encryption|Signal" | head -20
echo ""
echo "\U1F4A1 Educational Note: This shows how easy it is to see nearby networks"
echo "   In real attacks, malicious actors often mimic these legitimate networks"
echo ""

# Rest of the lab setup (steps 3-8) should follow here,
# including cleanup, AP creation, captive portal, monitoring scripts, etc.
# These remain unchanged from the original script.

# You can re-insert your full remaining script here starting from:
# "echo \"\U1F6E0 STEP 3: Lab Environment Setup\""
# onward...

# For brevity, that section is omitted since your request was just to move the install logic up.

# If you want the full script with all steps reinserted and rewritten cleanly, let me know.
