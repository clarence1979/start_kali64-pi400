#!/bin/bash

LOGDIR=~/kismetlogs
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
PCAP_NAME="Kismet-$TIMESTAMP.pcapng"

echo "[*] Creating log directory at: $LOGDIR"
mkdir -p "$LOGDIR"

# 1. Check if Kismet is already running
if pgrep -x "kismet" > /dev/null; then
    echo "[!] Kismet is already running. No action taken."
    exit 0
fi

# 2. Check for any interface already in monitor mode
echo "[*] Checking for existing monitor-mode interfaces..."
mon_iface=$(iw dev | awk '/Interface/ {iface=$2} /type/ && $2=="monitor" {print iface}')

if [ -n "$mon_iface" ]; then
    echo "[+] Monitor mode already active on: $mon_iface"
    echo "[*] Launching Kismet on $mon_iface..."
    sudo kismet -c "$mon_iface" --log-types pcapng --log-prefix "$LOGDIR/$PCAP_NAME"
    exit 0
fi

# 3. No monitor interface found — scan for usable interfaces
echo "[*] Detecting wireless interfaces..."
interfaces=$(iw dev | grep Interface | awk '{print $2}')

if [ -z "$interfaces" ]; then
    echo "[!] No wireless interfaces found."
    exit 1
fi

# 4. Loop through and try to enable monitor mode
for iface in $interfaces; do
    echo "[*] Checking $iface for monitor mode support..."
    
    sudo ip link set "$iface" down
    sudo iw "$iface" set monitor control 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[+] $iface supports monitor mode."

        sudo airmon-ng start "$iface" > /dev/null 2>&1
        sleep 2

        mon_iface=$(iw dev | awk '/Interface/ {iface=$2} /type/ && $2=="monitor" {print iface}')

        if [ -z "$mon_iface" ]; then
            echo "[!] Failed to retrieve monitor interface name."
            exit 1
        fi

        echo "[+] Monitor mode enabled: $mon_iface"
        echo "[*] Launching Kismet on $mon_iface..."
        sudo kismet -c "$mon_iface" --log-types pcapng --log-prefix "$LOGDIR/$PCAP_NAME"
        exit 0
    else
        echo "[-] $iface does not support monitor mode or failed to enable it."
        sudo ip link set "$iface" up
    fi
done

echo "[!] No suitable wireless interface found that supports monitor mode."
exit 1
