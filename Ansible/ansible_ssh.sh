#! /bin/bash
#----------------------------
# Step 1: Generate SSH key
#----------------------------
INVENTORY_FILE="./inventory"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
read -p "Enter the remote SSH username to use in Ansible (e.g., student): " REMOTE_USER

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "[+] Generating SSH key at $SSH_KEY_PATH..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
else
    echo "[✔] SSH key already exists at $SSH_KEY_PATH"
fi

#----------------------------
# Step 2: Use ad-hoc command to push public key
#----------------------------

PUB_KEY=$(cat "$SSH_KEY_PATH.pub")

echo "[+] Copying SSH key to managed nodes via Ansible ad-hoc command..."
ansible all -i "$INVENTORY_FILE" \
  -m authorized_key \
  -a "user=$REMOTE_USER state=present key='$PUB_KEY'" \
  -u "$REMOTE_USER" --ask-pass

echo "[✔] SSH key distributed successfully."
