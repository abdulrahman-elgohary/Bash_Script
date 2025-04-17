#!/bin/bash

echo "[+] Setting up Ansible environment..."

#----------------------------
# Step 1: Create inventory file
#----------------------------

INVENTORY_FILE="./inventory"
echo "[+] Creating Ansible inventory at $INVENTORY_FILE..."

read -p "How many groups do you want to define in the inventory? " GROUP_COUNT
if ! [[ "$GROUP_COUNT" =~ ^[0-9]+$ ]]; then
  echo "❌ Invalid number of groups. Exiting."
  exit 1
fi

> "$INVENTORY_FILE"  # Truncate or create inventory

for (( i=1; i<=GROUP_COUNT; i++ )); do
    read -p "Enter name for group #$i: " GROUP_NAME
    echo "[$GROUP_NAME]" >> "$INVENTORY_FILE"

    read -p "How many hosts in group '$GROUP_NAME'? " HOST_COUNT
    if ! [[ "$HOST_COUNT" =~ ^[0-9]+$ ]]; then
      echo "❌ Invalid number of hosts. Exiting."
      exit 1
    fi

    for (( j=1; j<=HOST_COUNT; j++ )); do
        read -p "Enter hostname #$j for group '$GROUP_NAME': " HOST_NAME
        echo "$HOST_NAME" >> "$INVENTORY_FILE"
    done

    echo "" >> "$INVENTORY_FILE"
done

echo "[✔] Inventory created at $INVENTORY_FILE"

#----------------------------
# Step 2: Generate ansible.cfg
#----------------------------

read -p "Enter the remote SSH username to use in Ansible (e.g., student): " REMOTE_USER
ANSIBLE_CFG_FILE="./ansible.cfg"

cat > "$ANSIBLE_CFG_FILE" <<EOF
[defaults]
remote_user = $REMOTE_USER
inventory = ./inventory
host_key_checking = false
roles_path = roles:/usr/share/ansible/roles:/etc/ansible/roles
collections_path = collections:/usr/share/ansible/collections

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
EOF

echo "[✔] ansible.cfg created at $ANSIBLE_CFG_FILE"

#----------------------------
# Step 3: Generate SSH key
#----------------------------

SSH_KEY_PATH="$HOME/.ssh/id_rsa"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "[+] Generating SSH key at $SSH_KEY_PATH..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
else
    echo "[✔] SSH key already exists at $SSH_KEY_PATH"
fi

#----------------------------
# Step 4: Use ad-hoc command to push public key
#----------------------------

PUB_KEY=$(cat "$SSH_KEY_PATH.pub")

echo "[+] Copying SSH key to managed nodes via Ansible ad-hoc command..."
ansible all -i "$INVENTORY_FILE" \
  -m authorized_key \
  -a "user=$REMOTE_USER state=present key='$PUB_KEY'" \
  -u "$REMOTE_USER" --ask-pass

echo "[✔] SSH key distributed successfully."
