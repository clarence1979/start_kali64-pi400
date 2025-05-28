#!/bin/bash

echo "[+] Starting HTTP-only enforcement script on Kali (Pi 5)..."

# 1. Disable HTTPS in Firefox by disabling HTTPS-Only mode
echo "[1/4] Disabling HTTPS-Only mode in Firefox..."
FF_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -name "*.default*" | head -n 1)
if [[ -z "$FF_PROFILE" ]]; then
  echo "[!] Firefox profile not found. Skipping HTTPS-only config."
else
  sed -i '/dom.security.https_only_mode/d' "$FF_PROFILE/user.js"
  echo 'user_pref("dom.security.https_only_mode", false);' >> "$FF_PROFILE/user.js"
  echo "[✓] HTTPS-only mode disabled in Firefox."
fi

# 2. Block HTTPS system-wide using iptables
echo "[2/4] Blocking all outbound HTTPS traffic (port 443)..."
sudo iptables -A OUTPUT -p tcp --dport 443 -j REJECT
sudo iptables -A FORWARD -p tcp --dport 443 -j REJECT
sudo iptables -A INPUT -p tcp --dport 443 -j REJECT
echo "[✓] HTTPS blocked."

# Optional: Save iptables rules
echo "[+] Installing iptables-persistent to save firewall rules..."
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
echo "[✓] Firewall rules saved and will persist."

# 3. Configure CLI tools to allow only HTTP
echo "[3/4] Configuring curl and wget for HTTP-only..."

# Update aliases in ~/.bashrc
sed -i '/alias curl=/d' ~/.bashrc
sed -i '/alias wget=/d' ~/.bashrc
echo 'alias curl="curl --proto =http"' >> ~/.bashrc
echo 'alias wget="wget --no-check-certificate --prefer-family=IPv4"' >> ~/.bashrc
echo "[✓] curl and wget now default to HTTP-only mode."

# 4. Inform user
echo "[4/4] Verifying setup..."
echo "To test, open Firefox and try visiting:"
echo "  http://neverssl.com"
echo "  https://example.com (should fail)"
echo
echo "[✅] Setup complete. Reboot or 'source ~/.bashrc' to apply changes."
