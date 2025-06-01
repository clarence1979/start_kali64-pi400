#!/bin/bash

# Define desktop location
DESKTOP="$HOME/Desktop"

# Define rockyou variants
ROCKYOU_TXT="rockyou.txt"
ROCKYOU_GZ="rockyou.txt.gz"
FOUND_PATH=""

# Search in common directories
SEARCH_PATHS=(
    "/usr/share/wordlists"
    "/usr/share"
    "/opt"
    "$HOME"
)

# Check for existing rockyou.txt or rockyou.txt.gz
for path in "${SEARCH_PATHS[@]}"; do
    if [[ -f "$path/$ROCKYOU_TXT" ]]; then
        echo "[+] Found $ROCKYOU_TXT at $path"
        cp "$path/$ROCKYOU_TXT" "$DESKTOP/"
        echo "[+] Copied to $DESKTOP"
        exit 0
    elif [[ -f "$path/$ROCKYOU_GZ" ]]; then
        echo "[+] Found $ROCKYOU_GZ at $path"
        cp "$path/$ROCKYOU_GZ" "$DESKTOP/"
        gunzip -f "$DESKTOP/$ROCKYOU_GZ"
        echo "[+] Decompressed to $DESKTOP/$ROCKYOU_TXT"
        exit 0
    fi
done

# If not found, download and extract
echo "[!] rockyou.txt(.gz) not found. Downloading from GitHub..."
cd "$DESKTOP" || exit 1
curl -L -o "$ROCKYOU_TXT" "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"

if [[ -f "$ROCKYOU_GZ" ]]; then
    echo "[+] Downloaded $ROCKYOU_GZ to $DESKTOP"
    gunzip -f "$ROCKYOU_GZ"
    echo "[+] Decompressed to $DESKTOP/$ROCKYOU_TXT"
else
    echo "[!] Download failed. Please check your internet connection."
    exit 1
fi
