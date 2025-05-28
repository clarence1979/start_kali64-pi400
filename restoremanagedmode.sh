# Restore managed mode
echo "[+] Restoring managed mode..."
sudo ip link set $WIFI_IFACE down
sudo iw $WIFI_IFACE set type managed
sudo ip link set $WIFI_IFACE up

echo "[✓] Interface $WIFI_IFACE restored to managed mode."
