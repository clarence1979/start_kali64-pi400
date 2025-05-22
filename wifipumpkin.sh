#!/bin/bash

# WiFi-Pumpkin installer and setup script for Kali on Pi 5
# Ensure this is run with: sudo ./install_wifi_pumpkin.sh

echo "[*] Updating and installing dependencies..."
apt update && apt upgrade -y
apt install -y git python3-pip python3-dev python3-setuptools libssl-dev libffi-dev \
               build-essential libpython3-dev libpcap-dev libnl-3-dev libnl-genl-3-dev \
               aircrack-ng hostapd dnsmasq iw net-tools xterm

echo "[*] Cloning WiFi-Pumpkin3 repository..."
cd /opt
if [ ! -d "WiFi-Pumpkin3" ]; then
    git clone https://github.com/P0cL4bs/WiFi-Pumpkin3.git
else
    echo "[*] WiFi-Pumpkin3 already cloned."
fi

cd WiFi-Pumpkin3
echo "[*] Installing WiFi-Pumpkin3 via pip..."
pip3 install -r requirements.txt

echo "[*] Creating symlink to run WiFi-Pumpkin3 from anywhere..."
ln -sf /opt/WiFi-Pumpkin3/wifipumpkin3 /usr/local/bin/wifipumpkin3

echo "[*] Detecting wireless interfaces..."
interfaces=$(iw dev | awk '$1=="Interface"{print $2}')
echo "Available interfaces: $interfaces"

# Find a wireless interface that supports monitor mode
for iface in $interfaces; do
    echo "[*] Checking $iface for monitor mode support..."
    if iw list | grep -A 10 "Interface $iface" | grep -q "monitor"; then
        echo "[+] $iface supports monitor mode."
        monitor_iface=$iface
        break
    fi
done

if [ -z "$monitor_iface" ]; then
    echo "[!] No compatible Wi-Fi adapter found that supports monitor mode."
    exit 1
fi

echo "[*] Killing conflicting processes..."
airmon-ng check kill

echo "[*] Enabling monitor mode on $monitor_iface..."
airmon-ng start "$monitor_iface"
mon_iface="${monitor_iface}mon"

echo "[*] Launching WiFi-Pumpkin3 with monitor interface $mon_iface..."
sleep 2
wifipumpkin3 --iface "$mon_iface"
