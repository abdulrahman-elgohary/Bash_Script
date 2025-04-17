#!/bin/bash

# Prompt for Red Hat credentials
read -p "Enter your Red Hat username: " RH_USERNAME
read -s -p "Enter your Red Hat password: " RH_PASSWORD
echo ""

# Enable the required repository
echo "[+] Enabling Ansible Automation Platform repo..."
sudo subscription-manager repos --enable=ansible-automation-platform-2.2-for-rhel-9-x86_64-rpms

# Install ansible-core and ansible-navigator
echo "[+] Installing ansible-core and ansible-navigator..."
sudo dnf install -y ansible-core ansible-navigator

# Login to registry.redhat.io using Podman
echo "[+] Logging into registry.redhat.io..."
echo "$RH_PASSWORD" | podman login registry.redhat.io --username "$RH_USERNAME" --password-stdin

# Pull required images using ansible-navigator
echo "[+] Pulling images using ansible-navigator (this may take a while)..."
ansible-navigator images

# Create .ansible-navigator.yml in the user's home directory
NAVIGATOR_CONFIG="$HOME/.ansible-navigator.yml"
echo "[+] Creating configuration file at $NAVIGATOR_CONFIG..."

cat > "$NAVIGATOR_CONFIG" <<EOF
---
ansible-navigator:
  execution-environment:
    image: ee-supported-rhel8:latest
    pull:
      policy: missing

  playbook-artifact:
    enable: false

  logging:
    file: /var/log/ansible-navigator.log
    append: true
    level: info
EOF

# Detect the logged-in user (assumes script run under that user with sudo privileges)
LOGGED_USER=$(logname)
LOG_FILE="/var/log/ansible-navigator.log"

echo "[+] Creating log file at $LOG_FILE..."
sudo touch "$LOG_FILE"
sudo chown "$LOGGED_USER:$LOGGED_USER" "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

echo "[✔] Log file created and ownership set to $LOGGED_USER"

